Shared Terraform files

This folder contains shared Terraform modules and variables files used by multiple projects in this repository.

Purpose:
- Keep common Terraform pieces centralized for reuse.

Notes:
- Inspect variables.tf and backend.tf before running terraform init/apply.
- Do not commit secrets; use tfvars or secure backend.