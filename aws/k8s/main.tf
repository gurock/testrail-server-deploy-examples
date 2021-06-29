data "aws_eks_cluster" "default" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "default" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.default.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.default.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
  load_config_file       = false
}

resource "local_file" "kubeconfig" {
  sensitive_content = templatefile("${path.module}/kubeconfig.tpl", {
    cluster_name = var.cluster_name,
    clusterca    = data.aws_eks_cluster.default.certificate_authority[0].data,
    endpoint     = data.aws_eks_cluster.default.endpoint,
    })
  filename          = "./kubeconfig-${var.cluster_name}"
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_name
  }
}

module "alb_controller" {
  source  = "./modules/aws-load-balancer-controller"

  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"

  aws_region_name  = var.region
  k8s_cluster_name = var.cluster_name

	depends_on = []
}

resource "helm_release" "nginx_ingress" {
  namespace  = kubernetes_namespace.app.metadata.0.name
  wait       = true
  timeout    = 600

  name       = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "v3.30.0"

  values = [
    file("values/ingress-nginx.yaml")
  ]
}

resource "helm_release" "cluster-autoscaler" {
  namespace  = "kube-system"
  wait       = true
  timeout    = 600

  name       = "cluster-autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.9.2"

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }
  set {
    name  = "awsRegion"
    value = var.region
  }
}

resource "helm_release" "aws-efs-csi-driver" {
  namespace  = "kube-system"
  wait       = false # doesn't work with true
  timeout    = 30

  name = "aws-efs-csi-driver"

  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"
  version    = "2.1.1"

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.eu-central-1.amazonaws.com/eks/aws-efs-csi-driver"
  }
  set {
    name  = "controller.serviceAccount.create"
    value = false
  }
  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }
}

resource "random_password" "cassandra" {
  length           = 32
  special          = true
}

resource "helm_release" "testrail" {
  namespace  = kubernetes_namespace.app.metadata.0.name
  wait       = true
  timeout    = 600

  name       = "testrail"

  chart      = "./../../charts/testrail"
  version    = "0.1.0"

  set {
    name  = "storage.efs_enabled"
    value = true
  }
  set {
    name  = "pvc.volumeHandle"
    value = var.efs_id
  }
  set {
    name  = "ingress.hosts.0.host"
    value = var.tr_domain
  }
  set {
    name  = "ingress.hosts.0.paths.0.path"
    value = "/"
  }
  set {
    name  = "tls"
    value = var.tls
  }
  set {
    name  = "ingress.tls.0.secretName"
    value = "testrail-tls"
  }
  set {
    name  = "ingress.tls.0.hosts.0"
    value = var.tr_domain
  }
  set {
    name  = "resources.limits.cpu"
    value = var.tr_resources.limits.cpu
  }
  set {
    name  = "resources.limits.memory"
    value = var.tr_resources.limits.memory
  }
  set {
    name  = "resources.requests.cpu"
    value = var.tr_resources.requests.cpu
  }
  set {
    name  = "resources.requests.memory"
    value = var.tr_resources.requests.memory
  }

  depends_on = [
    helm_release.nginx_ingress,
    helm_release.aws-efs-csi-driver,
  ]
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert-manager" {
  count      = var.tls == "letsencrypt" ? 1 : 0
  namespace  = "cert-manager"
  wait       = true
  timeout    = 600

  name       = "cert-manager"

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.4.0"

  set {
    name  = "installCRDs"
    value = true
  }
}

resource "kubectl_manifest" "issuer" {
  count     = var.tls == "letsencrypt" ? 1 : 0
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt
  namespace: ${kubernetes_namespace.app.metadata.0.name}
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${var.email}
    privateKeySecretRef:
      name: letsencrypt
    solvers:
    - selector: {}
      http01:
        ingress:
          class: nginx
YAML
}

resource "kubernetes_secret" "testrail-tls" {
  count = var.tls == "from_file" ? 1 : 0

  metadata {
    name      = "testrail-tls"
    namespace = kubernetes_namespace.app.metadata.0.name
  }

  data = {
    "tls.crt" = fileexists("${path.module}/ssl/server.crt") ? file("${path.module}/ssl/server.crt") : ""
    "tls.key" = fileexists("${path.module}/ssl/server.key") ? file("${path.module}/ssl/server.key") : ""
  }

  type = "kubernetes.io/tls"
}

data "kubectl_path_documents" "metric_server_manifests" {
  pattern = "${path.module}/components.yaml"
  disable_template = true
}

resource "kubectl_manifest" "metric_server" {
  count     = length(data.kubectl_path_documents.metric_server_manifests.documents)
  yaml_body = element(data.kubectl_path_documents.metric_server_manifests.documents, count.index)
  depends_on = [
    data.kubectl_path_documents.metric_server_manifests,
  ]
}
