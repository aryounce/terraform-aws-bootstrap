#!/bin/bash
#
# Generate Terraform HCL for a S3 backend created with CloudFormation.
#
# Use this to create backend configuration HCL based on the deployed bootstrap
# stack in 'terraform-bootstrap.yaml'. This script will assume you used the
# stack name in the example AWS CLI deployment command from the README.md.
#
# In case you need to use this for multiple state files or you have deployed
# mutiple S3 backends you can specify the state file key name as the first
# argument to this script, and the CloudFormation stack name as the second
# argument to this script.
#
# Usage: ./generate-backend-conf.sh [state-key-name] [cloudformation-stack-name]
#

[[ $(which jq) ]] || \
  {
    echo "This script requires the 'jq' command. See more @ https://stedolan.github.io/jq/" >> /dev/stderr
    exit 1
  }

echo "# Generating Terraform HCL for S3 backend" >> /dev/stderr

# TODO Document
state_key_default=terraform
state_key="${1-$state_key_default}"

[[ "${state_key}" == "${state_key_default}" ]] && \
  echo "# Using default Terraform state key: '${state_key}'" >> /dev/stderr

# TODO Document
stack_name_default="terraform-bootstrap"
stack_name="${2-$stack_name_default}"
[[ "${stack_name}" == "${stack_name_default}" ]] && \
  echo "# Using default CloudFormation stack name: '${stack_name}'" >> /dev/stderr

aws cloudformation describe-stacks --stack-name "${stack_name}" | \
jq -r --arg state_key "${state_key}" $'"terraform {
  backend \\"s3\\" {
    bucket         = \\"\(.Stacks[0] | .Outputs[] | select(.OutputKey == "Bucket") | .OutputValue)\\"
    key            = \\"\(.Stacks[0] | .Parameters[] | select(.ParameterKey == "S3StatePrefix") | .ParameterValue)/\($state_key).tfstate\\"
    region         = \\"\(.Stacks[0] | .StackId | split(":")[3])\\"
    dynamodb_table = \\"\(.Stacks[0] | .Parameters[] | select(.ParameterKey == "DynamoDbTableName") | .ParameterValue)\\"
    # Use of S3 bucket encryption must be enable by the user.
    #encrypt        = true
    #kms_key_id     = \\"alias/terraform-bucket-key\\"
 }
}"'
