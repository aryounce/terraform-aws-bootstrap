.PHONY: test-tf test-tf-clean test-cf test-cf-clean

# Use `testing/test-template.tfvars.json` to create a `tfvars.json for your own
# testing. Both the Terraform and CloudFormation test variables follow the same
# format, which uses JSON for cross-test compatibility.

TF_TEST_TFVARS := test-tf.tfvars.json

CF_TEST_TFVARS := test-cf.tfvars.json
CF_TEST_STACK := terraform-s3be-bootstrap-test

#
# Setup an S3 backend using Terraform and create sample infrastructure to
# exercise it.
#
test-tf:
	@echo "--- Deploying S3 backend with Terraform ---"
	terraform init -reconfigure && \
	terraform apply -auto-approve -var-file testing/${TF_TEST_TFVARS} -var 's3_bucket_versioning=false'
	@echo "--- Generating Terraform backend config for sample infrastructure ---"
	./generate-backend-hcl.sh $(shell jq -r '.parameter_prefix' < testing/${TF_TEST_TFVARS}) \
		> testing/sample-infra/backend.tf
	@echo "--- Deploying sample infrastructure ---"
	cd testing/sample-infra && \
		terraform init -reconfigure && \
		terraform apply -auto-approve -var 'sample_ssm_parameter_prefix=test-tf' && \
		terraform show

test-tf-clean:
	@echo "--- Tearing down sample infrastructure ---"
	cd testing/sample-infra && \
		terraform destroy -auto-approve -var 'sample_ssm_parameter_prefix=test-tf' && \
		terraform show
	@echo "--- Clearing all objects from backend S3 bucket ---"
	aws s3 rm s3://$(shell jq -r '.s3_bucket_name' < testing/${TF_TEST_TFVARS})/ --recursive
	@sleep 5
	@echo "--- Tearing down S3 backend infrastructure ---"
	terraform destroy -auto-approve -var-file testing/${TF_TEST_TFVARS}
	@echo "--- Cleaning up local S3 backend state ---"
	rm -rf testing/.terraform testing/.terraform.lock.hcl testing/sample-infra/backend.tf

#
# Setup an S3 backend using CloudFormation and create sample infrastructure to
# exercise it.
#
test-cf:
	@echo "--- Deploying S3 backend with CloudFormation ---"
	aws cloudformation deploy \
		--stack-name ${CF_TEST_STACK} \
		--template-file terraform-bootstrap.yaml \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			S3StatePrefix=$(shell jq -r '.s3_key_prefix' < testing/${CF_TEST_TFVARS}) \
			S3Versioning=Disabled \
			S3BucketRetain=Disabled \
			PolicyName=$(shell jq -r '.iam_policy_name' < testing/${CF_TEST_TFVARS}) \
			ParameterPrefix=$(shell jq -r '.parameter_prefix' < testing/${CF_TEST_TFVARS})
	@echo "--- Generating Terraform backend config for sample infrastructure ---"
	./generate-backend-hcl.sh $(shell jq -r '.parameter_prefix' < testing/${CF_TEST_TFVARS}) \
		> testing/sample-infra/backend.tf
	@echo "--- Deploying sample infrastructure ---"
	cd testing/sample-infra && \
		terraform init -reconfigure && \
		terraform apply -auto-approve -var 'sample_ssm_parameter_prefix=test-cf' && \
		terraform show

test-cf-clean:
	@echo "--- Tearing down sample infrastructure ---"
	cd testing/sample-infra && \
		terraform destroy -auto-approve -var 'sample_ssm_parameter_prefix=test-cf' && \
		terraform show
	@echo "--- Clearing all objects from backend S3 bucket ---"
	aws s3 rm s3://$(shell aws cloudformation describe-stack-resource --stack-name ${CF_TEST_STACK} \
		--logical-resource-id Bucket | jq -r '.StackResourceDetail.PhysicalResourceId')/ --recursive
	@echo "--- Tearing down S3 backend infrastructure ---"
	aws cloudformation delete-stack --stack-name terraform-s3be-bootstrap-test
	@echo "--- Cleaning up local S3 backend state ---"
	rm -rf testing/.terraform testing/.terraform.lock.hcl testing/sample-infra/backend.tf
