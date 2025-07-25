#!/bin/bash
#
# Generate Terraform HCL for a S3 backend.
#
# Use this to create backend configuration HCL based on a deployment. This
# script will look in the AWS account to which your active credentials belong.
#
# In case you need to use this for multiple state files or you have deployed
# mutiple S3 backends you may specify the state name as the first argument to
# this script and the SSM Parameter Store path prefix as the second argument.
#
# Usage: ./generate-backend-conf.sh [state-name] [ssm-param-path-prefix]
#

set -eu -o pipefail

[[ $(which jq) ]] || {
  echo "This script requires the 'jq' command. See more @ https://stedolan.github.io/jq/" >> /dev/stderr
  exit 1
}

[[ $(which terraform) ]] || {
  echo "This script requires the 'terraform' command."
  exit 1
}

echo "# Generating Terraform HCL for S3 backend" >> /dev/stderr
echo "# > Usage: $0 [ssm-param-path-prefix] [state-name]" >> /dev/stderr

# SSM Parameter Store path prefix (for locating values needed by this script)
param_prefix_default="terraform"
param_prefix="$(echo ${1-${param_prefix_default}} | sed -E 's#^/*(.*[^/])/?/*$#\1#')"

[[ "${param_prefix}" == "${param_prefix_default}" ]] && \
  echo "# > Using *default* Terraform SSM parameter path: '${param_prefix}'" >> /dev/stderr

# Name of the state object in S3. Will have a .tfstate suffix in the bucket.
state_name_default="terraform"
state_name=${2-$state_name_default}

[[ "${state_name}" == "${state_name_default}" ]] && \
  echo "# > Using *default* Terraform state name: '${state_name}'" >> /dev/stderr

echo "# Reading parameters from SSM Parameter Store prefix: /${param_prefix}/" >> /dev/stderr

#
# Currently this only check that the number of returned Parameter Store values
# is greater than zero. Whether or not the expected parameters are returned is
# not (yet) handled gracefully.
#
aws ssm get-parameters-by-path --output json --path "/${param_prefix}" \
| jq -r --arg state_name "${state_name}" --arg param_prefix "${param_prefix}" \
$'if (.Parameters | length) > 0
then (.Parameters | map({ (.Name | tostring | trimstr("/") | ltrimstr($param_prefix) | trimstr("/")): .Value }) | add) |
"terraform {
  backend \\"s3\\" {
    // Change this to a CLI profile dedicated to the admin account or leave this
    // out entirely to use the session credentials.
    //profile       = \\"default\\"

    bucket        = \\"\(."s3-backend-bucket")\\"
    key           = \\"\(if ."s3-backend-prefix" then ."s3-backend-prefix" + "/" else "" end)\($state_name).tfstate\\"
    use_lockfile  = true

    // Use of S3 bucket encryption must be enable by the user.
    //encrypt        = true
    //kms_key_id     = \\"alias/terraform-bucket-key\\"
  }
}"
else
  "Error - No SSM Parameter Store values found at: /\($param_prefix)/"
end'
