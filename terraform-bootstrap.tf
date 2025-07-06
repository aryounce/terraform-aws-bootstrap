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
  type        = string
  default     = ""
  description = "AWS region for the backend resources. Will default to the session region."
}

/*
 * It should be noted that if you do not provide a name for the S3 bucket then
 * Terraform will assign a random, unique name. See;
 * https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#bucket
 */
variable "s3_bucket_name" {
  type        = string
  default     = null
  description = "Name for the S3 bucket created to store Terraform state."
}

variable "s3_key_prefix" {
  type        = string
  default     = null
  description = "Key prefix for the Terraform state objects in the S3 bucket."
}

variable "s3_bucket_versioning" {
  type        = bool
  default     = true
  description = "Optionally enable S3 object versioning on the backend's bucket."
}

variable "iam_policy_name" {
  type        = string
  default     = "Terraform-S3-Backend"
  description = "Name for the IAM policy enabling access to the backend."
}

/*
 * SSM Parameter Store values are created to provide a well-known place for
 * scripts and other automation to retieve the S3 bucket name and prefix.
 */
variable "parameter_prefix" {
  type    = string
  default = "terraform-state"
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
      version = ">= 6.2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

/*
 * Make the region and account ID available for use in resource parameters
 * (such as the managed IAM policy).
 */
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = can(var.s3_bucket_name) ? var.s3_bucket_name : null

  tags = {
    Name        = "Terraform S3 Backend - State"
    application = "Terraform S3 Backend"
  }

  lifecycle {
    # This is set to false to enable testing. Set this to `true` when deploying
    # in a production environment.
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  versioning_configuration {
    status = var.s3_bucket_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

/*
 * Attach this policy to an IAM user, group, or role to enable access to the S3
 * backend, see;
 * https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_manage-attach-detach.html
 */
resource "aws_iam_policy" "terraform_s3_backend_policy" {
  name        = var.iam_policy_name
  description = "Terraform S3 backend access."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Bucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.terraform_state_bucket.arn
      },
      {
        Sid    = "StateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = var.s3_key_prefix != null ? "${aws_s3_bucket.terraform_state_bucket.arn}/${var.s3_key_prefix}/*" : "${aws_s3_bucket.terraform_state_bucket.arn}/*"
      },
      {
        Sid    = "Parameters"
        Effect = "Allow"
        Action = [
          "ssm:DescribeParameters",
          "ssm:GetParameter",
          "ssm:GetParameterHistory",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.parameter_prefix}/*"
      }
    ]
  })
}

/*
 * To ensure that the S3 bucket and prefix are discoverable by scripts and other
 * forms of automation we put their names into well known locations in
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

resource "aws_ssm_parameter" "terraform_state_key_prefix" {
  name        = "/${var.parameter_prefix}/s3-backend-prefix"
  type        = "String"
  description = "Key prefix for Terraform state."
  value       = var.s3_key_prefix != null ? var.s3_key_prefix : ""

  tags = {
    application = "Terraform S3 Backend"
  }
}
