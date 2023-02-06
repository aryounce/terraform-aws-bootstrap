<img src="docs/banner.jpg" alt="Terraform Bootstrap for AWS">

Quickly get started with the [Terraform S3 backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3).

The included CloudFormation stack template solves the chicken-and-egg problem with the Terraform S3 backend by setting up all of the resources needed in the "administrative AWS account" so that Terraform may be used safely in a [multi-account, multi-user setup](https://developer.hashicorp.com/terraform/language/settings/backends/s3#multi-account-aws-architecture).

## Installation

Using appropriate AWS credentials, run the following:

```
aws cloudformation deploy --stack-name terraform-bootstrap --template-file terraform-bootstrap.yaml --capabilities CAPABILITY_NAMED_IAM
```

## Related Reading

- [Terraform S3 Backend Best Practices](https://technology.doximity.com/articles/terraform-s3-backend-best-practices)
