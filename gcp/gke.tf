data "google_client_config" "default" {}

locals {
  cluster_name = "${var.app_name}-${var.cluster_name_suffix}"
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster/"
  project_id                 = var.project_id
  name                       = local.cluster_name
  region                     = var.region
  network                    = module.gcp-network.network_name
  subnetwork                 = module.gcp-network.subnets_names[0]
  ip_range_pods              = var.ip_range_pods_name
  ip_range_services          = var.ip_range_services_name
  create_service_account     = true
  gce_pd_csi_driver          = var.gce_pd_csi_driver

  master_authorized_networks = concat(
    var.master_authorized_networks,
    [
     {
       cidr_block   = data.google_compute_subnetwork.subnetwork.ip_cidr_range
       display_name = "VPC"
     },
   ]
  )

  node_pools = [
    {
      name                      = "${var.app_name}-node-pool"
      machine_type              = var.node_type
      min_count                 = 1
      max_count                 = 40
      local_ssd_count           = 0
      disk_size_gb              = 100
      disk_type                 = "pd-ssd"
      image_type                = "COS_CONTAINERD"
      auto_repair               = true
      auto_upgrade              = false
      preemptible               = false
      initial_node_count        = 1
    },
  ]
}

# Enable Filestore CSI driver
# TODO Move this to module when supported
resource "null_resource" "EnableGcpFilestoreCsiDriver" {
  provisioner "local-exec" {
    command = "gcloud container clusters update ${local.cluster_name} --region=${var.region} --project=${var.project_id} --update-addons=GcpFilestoreCsiDriver=ENABLED"
  }
  depends_on = [module.gke]
}

module "gke_auth" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  depends_on   = [module.gke]
  project_id   = var.project_id
  location     = module.gke.location
  cluster_name = module.gke.name
}

resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "./k8s/kubeconfig-${module.gke.name}"
}

resource "local_file" "k8s_terraform_tfvars" {
  sensitive_content = templatefile("${path.module}/k8s/terraform.tfvars.tpl", {
    project_id   = var.project_id
    cluster_name = local.cluster_name,
    app_name     = var.app_name
    region       = var.region,
    tr_domain    = var.tr_domain,
    network      = var.network
    email        = var.email,
    tls          = var.tls,
    tr_resources = var.tr_resources,
    })
  filename          = "./k8s/terraform.tfvars"
  file_permission   = "0755"
}
