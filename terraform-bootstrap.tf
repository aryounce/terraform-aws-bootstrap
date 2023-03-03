/*
 * This Terraform configuration initializes all of the resources necessary to
 * utilize the Terraform S3 backend, see;
 * https://www.terraform.io/language/settings/backends/s3
 *
 * These resources are meant to reside in what the Terraform documentation refers
 * to as an "administrative AWS account". See;
 * https://developer.hashicorp.com/terraform/language/settings/backends/s3#multi-account-aws-architecture
 *
 * All variables are optional.
 */

variable "aws_region" {
  type    = string
  default = null
  description = "AWS region for the backend resources. Will default to the session region."
}

/*
 * It should be noted that if you do not provide a name for the S3 bucket then
 * Terraform will assign a random, unique name. See;
 * https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#bucket
 */
variable "s3_bucket_name" {
  type = string
  default = null
  description = "Name for the S3 bucket created to store Terraform state."
}

variable "dynamo_table_name" {
  type    = string
  default = "terraform-locking"
  description = "Name for the DynamocDB table created to lock Terraform state."
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
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.57.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

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
  name     = var.dynamo_table_name
  hash_key = "LockID"

  billing_mode = "PAY_PER_REQUEST"

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
  }
}


/*
 * To ensure that the S3 bucket and DynamoDB table are discoverable by scripts
 * and other forms of automation we put their names into well known locations in
 * Parameter Store.
 */

resource "aws_ssm_parameter" "terraform_state_bucket" {
  name        = "/${var.parameter_prefix}/s3-backend-bucket"
  type        = "String"
  description = "Bucket used for Terraform S3 backend deployment(s)."
  value       = aws_s3_bucket.terraform_state_bucket.id

  tags = {
    application = "Terraform S3 Backend"
  }
}

resource "aws_ssm_parameter" "terraform_lock_table" {
  name        = "/${var.parameter_prefix}/s3-backend-lock-table"
  type        = "String"
  description = "DynamoDB locking table used for Terraform S3 backend deployment(s)."
  value       = aws_dynamodb_table.terraform_lock_table.id

  tags = {
    application = "Terraform S3 Backend"
  }
}
