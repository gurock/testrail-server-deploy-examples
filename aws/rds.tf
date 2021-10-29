locals {
  rds_name = "${var.app_name}-${var.environment}"
  rds_tags = {
    Owner       = var.app_name
    Environment = var.environment
  }
}

resource "aws_security_group" "db_access" {
  name_prefix = "db_access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}

module "db" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "5.2.0"

  name                  = local.rds_name
  engine                = "aurora-mysql"
  engine_version        = "5.7.mysql_aurora.2.07.2"
  instance_type         = var.db_instance_type
  instance_type_replica = var.db_replica_type

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.database_subnets

  replica_count          = 2
  create_security_group  = false
  vpc_security_group_ids = [aws_security_group.db_access.id]

  storage_encrypted   = true
  apply_immediately   = true
  monitoring_interval = 10

  db_parameter_group_name         = aws_db_parameter_group.db_parameter_group.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.cluster_parameter_group.id
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  username      = var.database_username
  database_name = var.database_name

  tags = local.rds_tags
}

resource "aws_db_parameter_group" "db_parameter_group" {
  name        = "${local.rds_name}-aurora-db-57-parameter-group"
  family      = "aurora-mysql5.7"
  description = "${local.rds_name}-aurora-db-57-parameter-group"
  tags        = local.rds_tags
}

resource "aws_rds_cluster_parameter_group" "cluster_parameter_group" {
  name        = "${local.rds_name}-aurora-57-cluster-parameter-group"
  family      = "aurora-mysql5.7"
  description = "${local.rds_name}-aurora-57-cluster-parameter-group"
  tags        = local.rds_tags
}
