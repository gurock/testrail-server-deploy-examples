data "google_compute_zones" "available" {
  provider = google-beta

  region  = var.region
  project = var.project_id
}

module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 3.1"
  project_id   = var.project_id
  network_name = var.network

  subnets = [
    {
      subnet_name   = var.subnetwork
      subnet_ip     = "10.10.0.0/16"
      subnet_region = var.region
      #subnet_private_access = "true"
    },
    {
      subnet_name           = "${var.subnetwork}-private"
      subnet_ip             = "10.20.0.0/16"
      subnet_region         = var.region
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
      description           = "This is ${var.app_name} private subnet"
    },
  ]

  secondary_ranges = {
    (var.subnetwork) = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

data "google_compute_subnetwork" "subnetwork" {
  name       = var.subnetwork
  project    = var.project_id
  region     = var.region
  depends_on = [module.gcp-network]
}

resource "google_compute_firewall" "filestore" {
  name        = "filestore-firewall"
  description = "Access GCP filestore"
  network     = module.gcp-network.network_name
  project     = var.project_id

  source_ranges = ["10.10.0.0/16", "10.20.0.0/16"]

  allow {
    protocol = "tcp"
    ports    = ["111", "2046", "2049", "2050", "4045"]
  }
}
