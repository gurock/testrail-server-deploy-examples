variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "app_name" {
  default = "tr"
}

variable "network" {
  type = string
}

variable "tr_domain" {
  default = "tr.dev"
}

variable "tr_resources" {
  description = "Testrail resources requests and limits."
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits   = object({
      cpu    = string
      memory = string
    })
  })

  default = {
    requests   = {
      "cpu"    = "1200m"
      "memory" = "2048Mi"
    },
    limits   = {
      "cpu"    = "1200m"
      "memory" = "2048Mi"
    },
  }
}

variable "email" {
  default = "user@example.com"
}

variable "tls" {
  default = "letsencrypt"
}

