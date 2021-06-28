variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "app_name" {
  default = "tr"
}

variable "tr_domain" {
  default = "tr.dev"
}

variable "email" {
  default = "user@example.com"
}

variable "tls" {
  default = "letsencrypt"
}

variable "efs_id" {
  default = ""
}
