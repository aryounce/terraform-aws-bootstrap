<img src="docs/banner.png" alt="Terraform Bootstrap for AWS">

Quickly get started with the [Terraform S3 backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3).

These Terraform and CloudFormation templates solve the chicken-and-egg problem with the Terraform S3 backend by setting up all of the resources needed in the "administrative AWS account" so that Terraform may be used safely in a [multi-account, multi-user setup](https://developer.hashicorp.com/terraform/language/settings/backends/s3#multi-account-aws-architecture). This includes:

- An S3 bucket for Terraform state.
- A DynamoDB table for managing the state lock.
- A pre-built IAM policy that can be used for enabling access to the S3 backend.
- SSM Parameter Store values to make the S3 bucket name and DynamoDB table name accessible to other automation.

## Setup

Either the Terraform or CloudFormation template may be used as they are equivalent. Using appropriate AWS credentials for your "administrative" account, do the following:

### Via Terraform

Use the [Terraform template](terraform-bootstrap.tf) when you wish to manage everything in your AWS acccount(s) with Terraform. Additional steps are required to import the local state created when setting up the S3 backend.

For full instructions, see: [S3 backend setup via Terraform](docs/Setup-Via-Terraform.md)

```shell
terraform apply
```

### Via CloudFormation

Use the [CloudFormation template](terraform-bootstrap.yaml) when either you don't intend to manage you AWS resources with Terraform, but wish to store your state in S3, or you wish to keep your backend resources outside of your Terraform state.

For full instructions, see: [S3 backend setup via CloudFormation](docs/Setup-Via-CloudFormation.md)

```
aws cloudformation deploy \
  --stack-name terraform-bootstrap \
  --template-file terraform-bootstrap.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

## Usage

After setup you must create your [Terraform configuration utilizing the newly initialized backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3#configuration) for state.

The included [`generate-backend-hcl.sh`](generate-backend-hcl.sh) script will pull the needed values from your administrative AWS account and generate a proper configuration for you. See the header comment of the script for more information.

### Terraform Backend Configuration Example

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-bootstrap-bucket-XXXXXXXXXXXXX"
    key            = "terraform-state/terraform.tfstate"
    dynamodb_table = "terraform-locking"
    region         = "us-east-1"
    profile        = "admin-acct-profile"
  }
}
```

### IAM Authentication for Multiple AWS Accounts

When using the S3 backend to store state for managing multiple AWS accounts you will need to authenticate against both the administrative AWS account (which contains the state) and the AWS account you wish to manage. Depending on your preferred approach the configuration of the S3 backend may need to be modified.

See the supplementary document: [IAM Authentication when using the Terraform S3 Backend](docs/S3-Backend-With-IAM.md)

## Related Reading

- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)
- [Terraform S3 Backend Best Practices](https://technology.doximity.com/articles/terraform-s3-backend-best-practices)
