terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 3.39.0, <4.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.0"
    }
		kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}
