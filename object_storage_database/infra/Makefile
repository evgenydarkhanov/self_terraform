T = terraform

init:
	$(T) init

validate:
	$(T) validate

plan:
	$(T) plan

apply:
	$(T) apply -auto-approve

destroy:
	$(T) destroy -auto-approve

clean:
	rm -rf .terraform/
	rm  .terraform.lock.hcl
	rm terraform.tfstate
	rm terraform.tfstate.backup
