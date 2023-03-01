# S3 backend setup via Terraform

Initially setup, customize, and migrate the Terraform S3 backend with Terraform.

## Setup

TODO: Cover

- Vanilla setup.
- Setup with customized variables.

## Migration into the S3 backend

When setting up the S3 backend using Terraform the state is stored locally and must be [migrated into the backend afterwards](https://developer.hashicorp.com/terraform/cli/commands/init#backend-initialization) (unless you wish to store the backend's state locally).

TODO: Show full process.