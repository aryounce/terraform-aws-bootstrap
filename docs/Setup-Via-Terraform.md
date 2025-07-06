# S3 backend setup via Terraform

Setup and customize the Terraform S3 backend through Terraform itself. This method is best suited for when you wish to manage all infrastructure via Terraform.

## Customizable Parameters

There are a small number of parameters that let you customize your S3 backend deployment. These parameters may be set on the command line with the `-var` flag. Multiple parameters may be specified by repeated use of `-var`. See the [Input Variables](https://developer.hashicorp.com/terraform/language/values/variables#input-variables) topic in the Terraform documentation.

For example;

```bash
terraform apply -var 's3_bucket_name=MyCustomBucketName' -var 'dynamo_table_name=my-table-name'
```

### S3 Bucket Name

```shell
-var "s3_bucket_name=MyCustomBucketName"
```

When left empty this will cause a new S3 bucket to be created with a somewhat random, but unique name.

### S3 State Prefix

```shell
-var "s3_key_prefix=my/custom/S3/key/prefix"
```

Overrides the default [key prefix](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html) in the S3 bucket which stores your Terraform state objects. Set to `/terraform-state` by default. Take care to the omitted the leading `/`.

### S3 Bucket Versioning

```shell
-var "s3_bucket_versioning=false"
```

Enabled by default. You may optionally disable S3 bucket versioning by setting this variable to `false`.

### IAM Policy Name

```shell
-var "iam_policy_name=my-policy-name"
```

Specify to override the default IAM policy name, which is `Terraform-S3-Backend`.

### SSM Parameter Store Prefix

```shell
-var "parameter_prefix=my/param/prefix"
```

Override the prefix of the [SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) values that are created to store the S3 bucket name and DynamoDB table. Set to `/terraform` by default. Take care to the omitted the leading `/`.

## Migration into the S3 backend

When setting up the S3 backend using Terraform the state is stored locally and must be [migrated into the backend afterwards](https://developer.hashicorp.com/terraform/cli/commands/init#backend-initialization) (unless you wish to store the backend's state locally).

Once your backend configuration has been setup (see the project README for more information) you may then run the following to migrate your local state into the S3 backend:

```shell
terraform init -migrate-state
```

You will be prompted for confirmation by Terraform, the backend will be initialized, and your local state will be copied into the new backend.
