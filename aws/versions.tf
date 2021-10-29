terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws        = ">= 3.63.0"
    local      = ">= 2.1.0"
    random     = ">= 3.1.0"
    kubernetes = "~> 2.6"
  }
}
