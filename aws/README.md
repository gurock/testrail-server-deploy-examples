## Testrail on AWS (EKS + RDS + EFS)

This example demostrates the way to deploy testrail on AWS

**Note**: this example requires Kubernetes v1.19+

You will need the following environment variables to be set:
```
    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY
```

### Prerequisite setup

1. terraform (https://www.terraform.io/downloads.html)
2. aws cli
3. aws-iam-authenticator (https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)

### Create [StorageClass](./terraform.tfvars)
```
region        = "eu-central-1"
environment   = "dev"
app_name      = "tr"

#
## AWS EKS Cluster size
#
node_instance_type        = "c5.large"
node_asg_desired_capacity = 4

#
## DB settings
#
db_instance_type  = "db.t3.medium"
db_replica_type   = "db.t3.medium"
database_username = "tr"
database_name     = "tr"
```

### Create EKS cluster
```
terraform init
terraform apply --auto-approve
```
### Deploy the Example
Change into the k8s directory and create the Testrail resources.
```
cd k8s
terraform init
terraform apply --auto-approve
```

