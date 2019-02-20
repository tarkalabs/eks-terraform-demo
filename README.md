# Setup EKS cluster with MySQL RDS instance

This is a sample terraform file to setup your backend. This sets up a EKS cluster with two nodes. It also sets up an RDS instance in the same VPC accessible by the kubernetes nodes.

## Running

You have to supply `rds-db-password` variable from either the command line or stick it into a `secret.tfvars` file and pass it into terraform. Once terraform succeeds, you can access the kubeconfig which is exposed as an output.

    terraform output kubeconfig > kubeconfig.yaml
    export KUBECONFIG=`pwd`/kubeconfig.yaml

You will also have to add the IAM role to allow nodes to register themselves with the cluster. You can do that with the following commands. You will also need the [AWS IAM Authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator). If you are on osx, you can get it with homebrew (`brew install aws-iam-authenticator`).

    terraform output config_map_aws_auth > configmap.yaml
    kubectl create -f configmap.yaml
    kubectl get nodes

Look at `outputs.tf` for RDS specific exports.

## Backend

It is advisible that you setup the state on S3. I have checked in a sample `backend.tf`. You can generate the required resources with terraform itself on a separate project using the following plan.

```
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform-state" {
  bucket = "your-bucket-name"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags {
    Name = "S3 Remote Terraform State Store"
  }
}

resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name           = "your-dynamo-table-name"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  tags {
    Name = "DynamoDB Terraform State Lock Table"
  }
}

locals {
  s3_backend_config = <<BACKEND_CONFIG
terraform {
 backend “s3” {
 bucket = "${aws_s3_bucket.terraform-state.id}"
 dynamodb_table = "${aws_dynamodb_table.dynamodb-terraform-state-lock.id}"
 region = "us-east-1"
 key = "terraform-state/state.tfstate"
 }
}
BACKEND_CONFIG
}

output "s3_backend_config" {
  value = "${local.s3_backend_config}"
}
```
