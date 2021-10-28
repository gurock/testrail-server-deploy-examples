locals {
  mysql_ha_name = "${var.app_name}-mysql"
  read_replica_ip_configuration = {
    ipv4_enabled    = true
    require_ssl     = false
    private_network = module.gcp-network.network_self_link
    authorized_networks = [
      {
        name  = "${var.project_id}-cidr"
        value = var.mysql_ha_external_ip_range
      },
    ]
  }
}

resource "random_shuffle" "az" {
  input        = data.google_compute_zones.available.names
  result_count = 1
}

module "private-service-access" {
  source      = "GoogleCloudPlatform/sql-db/google//modules/private_service_access"
  version     = "8.0.0"
  project_id  = var.project_id
  vpc_network = module.gcp-network.network_name
  depends_on  = [module.gcp-network]
}

resource "random_password" "database_password" {
  length           = 32
  special          = true
}

module "mysql" {
  source               = "GoogleCloudPlatform/sql-db/google//modules/mysql"
  version              = "8.0.0"
  name                 = local.mysql_ha_name
  random_instance_name = true
  project_id           = var.project_id
  database_version     = "MYSQL_8_0"
  region               = var.region
  disk_size            = var.mysql_disk_size
  disk_type            = var.mysql_disk_type

  deletion_protection = false

  // Master configurations
  tier                            = var.mysql_instance_tier
  zone                            = element(random_shuffle.az.result, 0)
  availability_type               = "REGIONAL"
  maintenance_window_day          = 7
  maintenance_window_hour         = 12
  maintenance_window_update_track = "stable"

  database_flags = [{ name = "long_query_time", value = 1 }]

  user_labels = {
    app = var.app_name
  }

  ip_configuration = {
    ipv4_enabled    = true
    require_ssl     = true
    private_network = module.gcp-network.network_self_link
    authorized_networks = [
      {
        name  = "${var.project_id}-cidr"
        value = var.mysql_ha_external_ip_range
      },
    ]
  }

  backup_configuration = {
    enabled                        = true
    binary_log_enabled             = true
    start_time                     = "20:55"
    location                       = null
    transaction_log_retention_days = null
    retained_backups               = 14
    retention_unit                 = "COUNT"
  }

  // Read replica configurations
  read_replica_name_suffix = "-ro"
  read_replicas = [
    {
      name                = "0"
      zone                = element(random_shuffle.az.result, 1)
      tier                = var.mysql_replica_tier
      ip_configuration    = local.read_replica_ip_configuration
      database_flags      = [{ name = "long_query_time", value = 1 }]
      disk_autoresize     = true
      disk_size           = var.mysql_disk_size
      disk_type           = "PD_HDD"
      user_labels         = { app = var.app_name, ro = true, replica = true }
      encryption_key_name = null
    },
  ]

  db_name      = local.mysql_ha_name
  db_charset   = "utf8mb4"
  db_collation = "utf8mb4_general_ci"

  user_name     = var.app_name
  user_password = random_password.database_password.result

  depends_on = [module.private-service-access]
}
