#
# Sample infrastructure for testing the Terraform S3 backend. Use this to
# create infrastructure and state that uses the backend.
#

variable "aws_region" {
  type        = string
  default     = ""
  description = "Target AWS region. Will default to the session region."
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
