locals {
  cluster_name = var.cluster_name
}

provider "google" {}

data "google_client_config" "default" {}

data "google_container_cluster" "default" {
  name     = local.cluster_name
  project  = var.project_id
  location = var.region
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.default.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.default.master_auth[0].cluster_ca_certificate,
  )
}

provider "helm" {
  kubernetes {
    host  = "https://${data.google_container_cluster.default.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.default.master_auth[0].cluster_ca_certificate,
    )
  }
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
  version    = "v4.0.6"

  values = [
    file("values/ingress-nginx.yaml")
  ]
}

resource "helm_release" "testrail" {
  namespace  = kubernetes_namespace.app.metadata.0.name
  wait       = true
  timeout    = 600

  name       = "testrail"

  chart      = "./../../charts/testrail"
  version    = "0.1.0"

  set {
    name  = "storage.csi_enabled"
    value = true
  }
  set {
    name  = "pvc.network"
    value = var.network
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
  version    = "v1.6.0"

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
  depends_on = [
    helm_release.cert-manager,
  ]
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
