variable "region" {
  default = "us-west-2"
}

variable "environment" {
  default = "dev"
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

variable "node_instance_type" {
  default = "c5.large"
}

variable "node_asg_desired_capacity" {
  default = "1"
}

variable "node_asg_min_size" {
  default = "1"
}

variable "node_asg_max_size" {
  default = "2"
}

variable "db_instance_type" {
  default = "db.t3.medium"
}

variable "db_replica_type" {
  default = "db.t3.medium"
}

variable "database_username" {
  default = "tr"
}

variable "database_name" {
  default = "tr"
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)

  default = [
    "800644139400",
  ]
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      rolearn  = "arn:aws:iam::800644139400:role/tr-role"
      username = "tr"
      groups   = ["system:masters"]
    },
  ]
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      userarn  = "arn:aws:iam::800644139400:user/tr"
      username = "tr"
      groups   = ["system:masters"]
    },
  ]
}

variable "iam_path" {
  description = "If provided, all IAM roles will be created on this path."
  type        = string
  default     = "/"
}
