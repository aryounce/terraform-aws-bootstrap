#
# Sample infrastructure for testing the Terraform S3 backend. Use this to
# create infrastructure and state that uses the backend.
#

variable "sample_ssm_parameter_prefix" {
  type        = string
  default     = "test-123"
  description = "Prefix for sample Parameter Store entry."
}

resource "aws_ssm_parameter" "test-param" {
  name  = "/${var.sample_ssm_parameter_prefix}/test"
  type  = "String"
  value = "Sample SSM Parameter used for Terraform S3 backend testing."
}
