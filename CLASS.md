# Class 31 — Terraform: Infrastructure as Code Intro

## Objective
Clicking in cloud consoles is not reproducible, not reviewable, and not recoverable. When your
production RDS instance was created by clicking through the AWS console 18 months ago with no
documentation, a DR drill becomes a guessing game. Terraform makes your infrastructure a Git
commit: versioned, diffable, peer-reviewed, and exactly reproducible. `terraform destroy &&
terraform apply` recreates your entire environment identically, from scratch, in minutes.

## Why This Matters in Production
A team at a mid-size SaaS company had a production database fail. The recovery runbook said
"restore the DB." Nobody knew which VPC, which subnet group, which security group, which
PostgreSQL parameter group, or what backup retention was configured. The recreation took 4
hours of guessing while production was down. With Terraform: open `terraform/rds.tf`, read
the exact configuration, run `terraform apply`, done in 15 minutes. ClickOps infrastructure
is undocumented by definition. Every senior cloud engineer has a version of this story.
HashiCorp reports over 14 million Terraform downloads per month — it is the industry standard.

## What You'll Learn
- The difference between declarative IaC (Terraform) and imperative scripting (bash + AWS CLI)
- The `init / plan / apply / destroy` lifecycle and what each step does
- What the state file is, why it matters, and why it must never be committed to Git
- How `sensitive = true` prevents passwords from appearing in plan output
- Why `terraform plan` must always precede `terraform apply` — even for small changes
- How `default_tags` in the provider block ensures consistent tagging across all resources

## What Changed in This Class
- `terraform/main.tf` — terraform block with version constraints, local backend, AWS provider
- `terraform/variables.tf` — input variables including db_password with sensitive=true
- `terraform/outputs.tf` — vpc_id, subnet_ids, rds_endpoint exposed as outputs
- `terraform/vpc.tf` — VPC, 2 public subnets, 2 private subnets, IGW, route tables
- `terraform/security_groups.tf` — app SG (80/443 open), RDS SG (5432 from app SG only)
- `terraform/rds.tf` — PostgreSQL 15.4 on db.t3.micro in private subnets
- `terraform/.gitignore` — excludes *.tfstate, *.tfvars, .terraform/
- `terraform/terraform.tfvars.example` — committed template showing variable structure
- `Makefile` — added tf-init, tf-plan, tf-apply, tf-destroy, tf-fmt, tf-validate targets

## Concept Deep Dive

**Declarative vs imperative IaC** — A bash script that calls `aws ec2 create-vpc` is
imperative: it describes steps to execute. If the VPC already exists, the script creates a
second one, or errors. Terraform is declarative: you describe the desired state, and Terraform
figures out the steps to reach it. Running `terraform apply` twice is safe — the second run
finds no drift and makes no changes. This idempotency is the core property that makes
Terraform usable in CI/CD without guards against double-execution.

**The state file** — Terraform's state file (`terraform.tfstate`) is the mapping between your
configuration and the real cloud resources. It stores resource IDs, attribute values, and
dependency relationships. Without state, Terraform cannot know that `aws_vpc.main` in your
config corresponds to `vpc-0abc123` in AWS. The state file can contain sensitive values (RDS
passwords, certificate private keys) which is why it must never be committed to Git and must
be stored in a secure, shared backend (S3 + DynamoDB in class-32).

**Always plan before apply** — `terraform plan` reads current state, queries AWS for actual
resource attributes, computes the diff, and shows you exactly what will be created, modified,
or destroyed before any change is made. A common war story: an engineer runs `terraform apply`
without planning, not realizing a variable change would trigger a database replacement
(`-/+ destroy and then create replacement`). RDS replacements delete the original instance
first. The plan would have shown this in red with `# forces replacement`. Always plan.

## Hands-On Exercise
1. Install Terraform: `brew install terraform` or download from developer.hashicorp.com
2. Initialize: `make tf-init` — downloads the AWS provider plugin
3. Validate syntax: `make tf-validate`
4. Check formatting: `make tf-fmt`
5. Preview changes: `cd terraform && terraform plan -var="environment=dev" -var="db_password=testonly"`
   Read the output carefully — how many resources will be created?
6. Note: `db_password` shows as `(sensitive value)` in plan output — this is correct
7. Do NOT apply yet — class-32 first sets up remote state so the state file is not local

## Common Mistakes
1. **Committing the state file** — `terraform.tfstate` is generated automatically and contains
   resource IDs and sometimes sensitive values. It belongs in `.gitignore` immediately. If it
   gets committed, rotate any sensitive values it contains and remove it from history with
   `git filter-branch` or `git-filter-repo`.
2. **Running `terraform apply` without reviewing the plan** — The apply command shows the plan
   again and asks for confirmation, but engineers in a hurry type `yes` without reading. In CI
   always save the plan to a file (`terraform plan -out=tfplan`) and apply only that file
   (`terraform apply tfplan`), which skips the interactive prompt and guarantees you apply
   exactly what was reviewed.
3. **Hardcoding sensitive values** — `db_password = "mysecretpassword"` in any `.tf` file is
   committed to Git history. Use `variable "db_password" { sensitive = true }` and pass it
   via `TF_VAR_db_password` environment variable from your CI secrets store. The variable
   file approach (`terraform.tfvars`) is acceptable only if the file is in `.gitignore`.

## Next Class Preview
Class 32 extracts the VPC and RDS into reusable modules and switches to S3 remote state with
DynamoDB locking — so the state file is never on any engineer's laptop.
