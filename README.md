# Terraform Bootstrap for AWS

Quickly get started with the [Terraform S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3).

These Terraform and CloudFormation templates solve the chicken-and-egg problem with the Terraform S3 backend by setting up all of the resources needed in the "administrative AWS account" so that Terraform may be used safely in a [multi-account, multi-user setup](https://developer.hashicorp.com/terraform/language/settings/backends/s3#multi-account-aws-architecture). This includes:

- A S3 bucket for Terraform state.
- A pre-built IAM policy that can be used for enabling access to the S3 backend.
- SSM Parameter Store values to make the S3 bucket name and prefix accessible to other workloads.

## Setup

Either the Terraform or CloudFormation template may be used as they are equivalent. Using appropriate AWS credentials for your "administrative" account, do the following:

### Via Terraform

Use the [Terraform template](terraform-bootstrap.tf) when you wish to manage everything in your AWS acccount(s) with Terraform. Additional steps are required to import the local state created when setting up the S3 backend.

For full instructions, see: [S3 backend setup via Terraform](docs/Setup-Via-Terraform.md)

```shell
terraform apply
```

### Via CloudFormation

Use the [CloudFormation template](terraform-bootstrap.yaml) when either you don't intend to manage your AWS resources with Terraform, but wish to store your state in S3, or you wish to keep your backend resources outside of your Terraform state.

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
    region         = "us-east-1"
    profile        = "admin-acct-profile"
    bucket         = "terraform-bootstrap-bucket-XXXXXXXXXXXXX"
    key            = "terraform-state/terraform.tfstate"
    use_lockfile   = true
  }
}
```

### Note about Encryption

Although omitted in the above example it is advised that you, at a minimum, use [server-side encryption with AWS managed keys](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingServerSideEncryption.html) to protect your Terraform state. Secrets are sometimes included in state data, depending on the provider, and should at least be protected to the level offered by the [AWS Key Manamgement Service](https://docs.aws.amazon.com/kms/latest/developerguide/data-protection.html).

As of January 5th, 2025 all *new and existing* S3 buckets will use a default S3-managed key to encrypt all uploaded objects (existing objects will not have server-side encryption applied). When creating a new S3 bucket with the code included in this repository you do not need to enable KMS keys (unless you wish) as Amazon S3 will automatically manage the default bucket key for you.

#### Addtional Reading

- [AWS S3 - Protecting data with encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html)
- [AWS S3 - Default encryption FAQ](https://docs.aws.amazon.com/AmazonS3/latest/userguide/default-encryption-faq.html)
- [Setting default server-side encryption behavior for Amazon S3 buckets](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-encryption.html)

### IAM Authentication for Multiple AWS Accounts

When using the S3 backend to store state for managing multiple AWS accounts you will need to authenticate against both the administrative AWS account with *background* credentials (from the CLI profile specified in the backend configuration) and the AWS account you wish to manage with *foreground* credentials. Depending on your preferred approach the configuration of the S3 backend may need to be modified.

## Related Reading

- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/backend) → Learn about how Terraform backends work and how to configure them.
- [How to Manage Terraform S3 Backend – Best Practices](https://spacelift.io/blog/terraform-s3-backend) → An alternate guide to setting up your remote state with the S3 backend.
