# IAM Credentials for the Terraform S3 Backend

When using the S3 backend to store state for Terraform-managed AWS infrastructure it is important to distinguish betwen the "administrative" AWS account and other AWS accounts that Terraform acts on. The S3 backend configuration is flexible enough to enable most AWS authentication scenarios.

This document convers the basic use cases and the reader is encouraged to review the [Credentials and Shared Configuration section](https://developer.hashicorp.com/terraform/language/settings/backends/s3#credentials-and-shared-configuration) of the Terraform S3 Backend Configuration documentation.

To simplify the discussion of which IAM credentials are being used for an operation this document refers to the following:

1. **Foreground Credentials** - IAM credentials, whether they are an API key ID and secret pair, an assumed role session, or otherwise, that can be found as part of the Terraform user's environment. This could be through environment variables, AWS CLI configuration, EC2 instance metadata, ECS task metadata, any of the aforementioned mechanisms as setup by a tool like `aws-vault`.
2. **Background Credentials** - IAM credentials that are specified in the S3 Backend configuration. When using Terraform to act upon the "administrative" AWS account *these may be the same* as the foreground credentials. When using Terraform to act upon any other AWS account they will be unique to that account.

## AWS Credential Resolution

Software that interacts with AWS accounts tends to follow a predicable process (sometimes referred to as the "credential chain"), defined by the AWS SDKs, to locate IAM credentials. The process is approximately the same between SDKs, but there may be differences. *Both* foreground and background credentials can be influenced by this process.

The following list of IAM credential sources, and their resolution order, [comes from the AWS Golang SDK](https://aws.github.io/aws-sdk-go-v2/docs/configuring-sdk/#specifying-credentials) and the [AWS SDKs and Tools reference guide](https://docs.aws.amazon.com/sdkref/latest/guide/overview.html).

- **Environment Variables**
  `AWS_ACCESS_KEY_ID`,` AWS_SECRET_ACCESS_KEY`, etc.
- **Shared configuration files**
  Files located in `~/.aws/` such as `config` and `credentials`. This is further influenced by which **profile** is specified as configuration profiles can be inherited and reference one another.
- **IAM role via ECS Task Metadata**
  For processes running as ECS tasks, or in an environment that emulates the ECS Task Metadata interface (like `aws-vault`).
- **IAM role via EC2 Instance Metadata**
  For processes running on EC2 instances, or in an environment that emulates the EC2 Instnace Metadata interface (like `aws-vault`).

### Related Reading

- [AWS SDKs and Tools - Reference Guide > Configuration](https://docs.aws.amazon.com/sdkref/latest/guide/creds-config-files.html)
- [AWS SDKs and Tools - Credentials and access](https://docs.aws.amazon.com/sdkref/latest/guide/access.html)
- [Environment variables to configure the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)



## "Administrative" AWS Account

This is the AWS account that Terraform uses to store its remote state. The backend configuration enables authentication for this account that is separate from the authentication needed for other AWS accounts you may use Terraform to manage.

When initially setting up the S3 backend you will need to use credentials that have permission to create the resources needed back the backend. Once created you can then use more limited permissions (which are included within this project's templates) to utilize the backend.

TODO

## Other AWS Accounts

TODO
