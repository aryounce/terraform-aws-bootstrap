.PHONY: lint

lint: terraform-bootstrap.yaml
	cfn-lint $<
