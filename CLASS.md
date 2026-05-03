# Class 32 — Terraform: Remote State + Modules

## Objective
The local state file on an engineer's laptop is a single point of failure. Modules prevent
copy-paste infrastructure across environments. This class addresses both: moving state to S3
with DynamoDB locking so any engineer on any machine can run Terraform safely, and extracting
VPC and RDS into reusable modules that enforce consistent configuration across dev and
production while allowing environment-specific sizing.

## Why This Matters in Production
A team's lead infrastructure engineer resigned. Their laptop was returned to IT and wiped. The
Terraform state file — mapping configuration to 47 real AWS resources — was on that laptop and
only that laptop. Running `terraform apply` without state would have attempted to create 47
new resources while the originals kept running, resulting in duplicate infrastructure, billing
chaos, and a state reconciliation nightmare. Remote state in S3 with versioning means: the
state file is never on any one person's machine, every change is versioned and recoverable,
and DynamoDB locking prevents two engineers from applying simultaneously and corrupting state.

## What You'll Learn
- How S3 + DynamoDB backend works: what happens during init, plan, apply, and on concurrent access
- How Terraform modules work: inputs via variables, outputs via outputs, no access to internals
- The DRY principle applied to infrastructure: one module definition, used for all environments
- The directory-per-environment pattern vs Terraform workspaces — when to use each
- How module output chaining works: `module.vpc.private_subnet_ids` feeds into `module.rds`

## What Changed in This Class
- `terraform/modules/vpc/main.tf` — reusable VPC module using `cidrsubnet()` for subnet calculation
- `terraform/modules/vpc/variables.tf` — module input contract: app_name, environment, region, vpc_cidr
- `terraform/modules/vpc/outputs.tf` — module output contract: vpc_id, subnet IDs
- `terraform/modules/rds/main.tf` — reusable RDS module accepting vpc_id and subnet_ids from vpc module
- `terraform/modules/rds/variables.tf` — inputs including instance_class and allocated_storage for sizing
- `terraform/modules/rds/outputs.tf` — endpoint, port, db_name, security_group_id
- `terraform/environments/dev/main.tf` — dev environment calling both modules with small sizing
- `terraform/environments/production/main.tf` — production calling same modules with production sizing
- `terraform/main.tf` — updated to show S3 backend config as commented instructions

## Concept Deep Dive

**Remote state backends** — The S3 backend stores state in an S3 object and uses a DynamoDB
item as a mutex (lock). When `terraform apply` starts it writes a lock item to DynamoDB. Any
concurrent apply attempt finds the lock and either waits or exits with a "state is locked"
error, preventing corruption. When the apply finishes the lock is released. S3 versioning
means every state change is stored as a new object version — you can roll back to a previous
state if a plan goes wrong. Terraform Cloud provides the same capability as a managed service
with a UI, audit log, and Sentinel policy enforcement.

**Module input/output contracts** — A module's `variables.tf` is its API. Callers must
provide all required variables and may override optional ones. A module's `outputs.tf` is its
public interface — callers can reference outputs but cannot access internal resource attributes
directly. This encapsulation is what makes modules reusable: the vpc module does not know or
care whether its caller is a dev environment or production, a single-region deployment or
multi-region. Changes inside the module that don't change the interface are invisible to callers.

**Directory-per-environment vs workspaces** — Terraform workspaces let you maintain multiple
state files from one configuration directory by switching with `terraform workspace select`.
This sounds convenient but creates coupling: a change to the configuration affects every
workspace simultaneously. The directory-per-environment pattern (this class) is more explicit:
each environment has its own directory, its own state, and its own variable values. A plan in
dev has zero chance of accidentally affecting production. For most teams the clarity of
directory-per-environment outweighs the repetition that modules eliminate anyway.

## Hands-On Exercise
1. Validate each module independently:
   `cd terraform/modules/vpc && terraform validate`
   `cd terraform/modules/rds && terraform validate`
2. Observe the module chaining in environments/dev/main.tf — `module.vpc.private_subnet_ids` passes VPC outputs to RDS inputs
3. To test with real state (requires AWS account):
   a. Create the S3 bucket and DynamoDB table (commands in main.tf comments)
   b. Create a `backend-dev.hcl` file with bucket/key/region/table values
   c. `cd terraform/environments/dev && terraform init -backend-config=../../backend-dev.hcl`
   d. `terraform plan -var="db_password=testonly"` — observe the plan uses module resources
4. Delete `.terraform/` and re-init — state is recovered from S3, nothing is lost

## Common Mistakes
1. **Importing the module path incorrectly** — `source = "../../modules/vpc"` must be a path
   relative to the calling file, not the project root. Getting this wrong produces a confusing
   "module not found" error. Always run `terraform init` after changing any `source` value —
   Terraform downloads and caches modules during init, not during plan.
2. **Accessing module internals directly** — `module.vpc.aws_vpc.this.id` does not work.
   Modules expose only what is declared in `outputs.tf`. If a caller needs a value, add it to
   the module's outputs. This is not a limitation — it is the contract that makes modules
   safe to refactor internally without breaking callers.
3. **Using one state file for all environments** — Even with modules, if dev and production
   share a state file a `terraform plan` for dev computes diffs against production resources.
   A mistake in dev's apply can modify production. Always use separate state keys or separate
   directories per environment. State isolation is non-negotiable for production safety.

## Next Class Preview
Class 33 adds `terraform/eks.tf` to provision the Kubernetes cluster itself — completing the
full stack from raw cloud infrastructure to running application.
