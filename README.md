# Setup EKS cluster with MySQL RDS instance

This is a sample terraform file to setup your backend. This sets up a EKS cluster with two nodes. It also sets up an RDS instance in the same VPC accessible by the kubernetes nodes.

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