locals {
  efs_name = "${var.app_name}-${var.environment}"
  efs_tags = {
    Owner       = var.app_name
    Environment = var.environment
  }
}

module "efs-0" {
  source     = "AustinCloudGuru/efs/aws"
  version    = "1.0.4"
  vpc_id     = module.vpc.vpc_id
  name       = local.efs_name
  subnet_ids = module.vpc.private_subnets
  encrypted  = true

  security_group_ingress = {
    default = {
      description = "NFS Inbound"
      from_port   = 2049
      protocol    = "tcp"
      to_port     = 2049
      self        = null
      cidr_blocks = ["10.0.0.0/8"]
    }
  }

  tags = local.efs_tags
}
