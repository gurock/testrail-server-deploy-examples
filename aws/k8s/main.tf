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

resource "helm_release" "nginx_ingress" {
  namespace  = kubernetes_namespace.app.metadata.0.name
  wait       = true
  timeout    = 600

  name       = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "v3.30.0"

  set {
    name  = "controller.replicaCount"
    value = 2
  }
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

resource "helm_release" "cassandra" {
  namespace  = kubernetes_namespace.app.metadata.0.name
  wait       = true
  timeout    = 600

  name       = "cassandra"

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "cassandra"
  version    = "7.6.1"

  set {
    name  = "replicaCount"
    value = 2
  }

  set {
    name  = "dbUser.user"
    value = "admin"
  }

  set {
    name  = "dbUser.password"
    value = random_password.cassandra.result
  }
}

resource "helm_release" "testrail" {
  namespace  = kubernetes_namespace.app.metadata.0.name
  wait       = true
  timeout    = 600

  name       = "testrail"

  chart      = "./../../charts/testrail"
  version    = "0.4.0"

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
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert-manager" {
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
