# S3 backend setup via CloudFormation

Setup and customize the Terraform S3 backend through CloudFormation. This method is best suited for situations where you do not wish to manage your AWS infrastructure through Terraform or do not wish to comingle your S3 backend resources with the rest of your AWS infrastructure.

Using the [AWS Command Line Interface](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/cloudformation/deploy.html) run the following for the default setup:

```
aws cloudformation deploy \
  --stack-name terraform-bootstrap \
  --template-file terraform-bootstrap.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

## Customizable Parameters

There are a small number of parameters that let you customize your S3 backend deployment. These parameters may be set on the command line with the `--parameter-overrides` flag. Multiple parameters may be specified by providing quoted `"Key1=Value1" "Key2=Value2" ...` pairs. For example;

```
aws cloudformation deploy \
  --stack-name terraform-bootstrap \
  --template-file terraform-bootstrap.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "S3BucketName=MyCustomBucketName"
```

### S3 Bucket Name

```
"S3BucketName=MyCustomBucketName"
```

When left empty this will cause a new S3 bucket to be created with a somewhat random, but unique name.

### S3 State Prefix

```
"S3StatePrefix=my/custom/S3/key/prefix"
```

Overrides the default [key prefix](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html) in the S3 bucket which stores your Terraform state objects, which is `/terraform-state` by default. When overriding please omit the leading `/`.

### S3 Bucket Versioning

```shell
"S3Versioning=Disabled"
```

Enabled by default. You may optionally disable S3 bucket versioning by setting this variable to anything other than `Enabled`.

### IAM Policy Name

```
"PolicyName=my-policy-name"
```

Specify to override the default name for the generated IAM policy, which is `Terraform-S3-Backend`.

### SSM Parameter Store Prefix

```
"ParameterPrefix=my/param/prefix"
```

Override the prefix of the [SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) values that are created to store the S3 bucket name and DynamoDB table, which is `/terraform` by default. When overriding please omit the leading `/`.
