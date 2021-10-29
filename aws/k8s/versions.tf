terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.6.1"
    }
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.63.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.13.0"
    }
  }
}
