/*
 * All variables are optional.
 */

variable "aws_region" {
  type    = string
  default = null
}

/*
 * It should be noted that if you do not provide a name for the S3 bucket then
 * Terraform will assign a random, unique name. See;
 * https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#bucket
 */
variable "s3_bucket_name" {
  type = string
}

variable "dynamo_table_name" {
  type    = string
  default = "terraform-locking"
}

/*
 * SSM Parameter Store values are created to provide a well-known place for
 * scripts and other automation to retieve the S3 bucket name and DynamocDB table
 * name.
 */
variable "parameter_prefix" {
  type    = string
  default = "terraform"
}

/*
 * The `aws` provider will use the various `AWS_*` environment variables expected
 * by the AWS CLI and SDKs. See;
 * https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables
 * https://registry.terraform.io/providers/hashicorp/aws/latest/docs#aws-configuration-reference
 *
 * Modify this section as needed.
 */
provider "aws" {}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = can(var.s3_bucket_name) ? var.s3_bucket_name : null

  tags = {
    Name        = "Terraform S3 Backend - State"
    application = "Terraform S3 Backend"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_lock_table" {
  name           = var.dynamo_table_name
  hash_key       = "LockID"

  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform S3 Backend - Locking"
    application = "Terraform S3 Backend"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [ "read_capacity", "write_capacity" ]
  }
}
