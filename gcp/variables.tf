variable "app_name" {
  description = "The application name"
  default = "tr"
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

variable "project_id" {
  description = "The project ID to host the cluster in"
}

variable "cluster_name_suffix" {
  description = "The suffix for the GKE cluster"
  default     = "-dev"
}

variable "node_type" {
  description = "Cluster node machine type"
  default     = "n2-standard-2"
}

variable "master_authorized_networks" {
  type        = list(object({ cidr_block = string, display_name = string }))
  description = "List of master authorized networks. If none are provided, disallow external access (except the cluster node IPs, which GKE automatically whitelists)."
  default     = []
}

variable "region" {
  description = "The region to host the cluster in"
}

variable "network" {
  description = "The VPC network created to host the cluster in"
  default     = "tr-network"
}

variable "subnetwork" {
  description = "The subnetwork created to host the cluster in"
  default     = "tr-subnet"
}

variable "ip_range_pods_name" {
  description = "The secondary ip range to use for pods"
  default     = "ip-range-pods"
}

variable "ip_range_services_name" {
  description = "The secondary ip range to use for services"
  default     = "ip-range-scv"
}

variable "gce_pd_csi_driver" {
  type        = bool
  description = "(Beta) Whether this cluster should enable the Google Compute Engine Persistent Disk Container Storage Interface (CSI) Driver."
  default     = true
}

variable "mysql_instance_tier" {
  type        = string
  description = "Mysql default instance tier"
  default     = "db-n1-standard-1"
}

variable "mysql_replica_tier" {
  type        = string
  description = "Mysql default instance replica tier"
  default     = "db-n1-standard-1"
}

variable "mysql_disk_size" {
  type        = number
  description = "The disk size for the master instance"
  default     = 50
}

variable "mysql_disk_type" {
  type        = string
  description = "The disk type for the master instance."
  default     = "PD_SSD"
}

variable "mysql_ha_external_ip_range" {
  type        = string
  description = "The ip range to allow connecting from/to Cloud SQL"
  default     = "192.10.10.10/32"
}

variable "basic_auth_username" {
  default = ""
}

variable "basic_auth_password" {
  default = ""
}
