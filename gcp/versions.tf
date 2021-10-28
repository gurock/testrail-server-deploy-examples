terraform {
  required_version = ">= 0.13.1"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.39.0, <4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-kubernetes-engine/v16.1.0"
  }
}
