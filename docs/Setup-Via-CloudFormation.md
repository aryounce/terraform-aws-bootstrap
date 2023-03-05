# S3 backend setup via CloudFormation

Initially setup and customize the Terraform S3 backend with through CloudFormation. This method is best suited for situations where you do not wish to manage AWS infrastructure through Terraform or do not wish to comingle your S3 backend resources with the rest of your AWS infrastructure.

Using the AWS Command Line Interface run the following for the default setup:

```
aws cloudformation deploy \
  --stack-name terraform-bootstrap \
  --template-file terraform-bootstrap.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

## Customizable Parameters

There are a small number of parameters that let you customize your S3 backend deployment. These parameters may be set on the command line with the `--parameter-overrides` flag. Multiple parameters may be specified by providing multiple, quoted `"Key1=Value1" "Key2=Value2"` pairs.

### S3 Bucket Name

When left empty this will cause a new S3 bucket to be created with a somewhat random, but unique name. You may override this with your own existing or new S3 bucket name by specifying `S3BucketName=MyCustomBucketName"`.

### S3 State Prefix

Overrides the default key prefix in the S3 bucket which stores your Terraform state objects. Set to `/terraform-state` by default, you may customize this to be `/my/custom/S3/key/prefix` by specifying `S3StatePrefix=my/custom/S3/key/prefix` (note the omitted leading `/`).

### DynamocDB Lock Table Name

Specify `DynamoDbTableName=my-table-name` to override the default DynamocDB table name (`terraform-locking`).

### SSM Parameter Store Prefix

Override the prefix of the SSM Parameter Store values that are created to store the S3 bucket name and DynamoDB table. Specify `"ParameterPrefix=my/param/prefix"` (note the omitted leading `/`).
