# Class 33 — Terraform + Kubernetes: Provision EKS

## Objective
The full picture: provision the Kubernetes cluster itself with Terraform, then deploy the
application into it. Every previous class assumed a cluster existed. This class removes that
assumption — the cluster, its node group, its IAM roles, and its networking all come from
`terraform apply`. `terraform destroy && terraform apply` gives you a fresh, identically
configured cluster in under 20 minutes.

## Why This Matters in Production
A contractor provisioned the production EKS cluster with `eksctl` flags nobody wrote down.
The Kubernetes version is unknown (auto-upgrade was disabled). The node IAM role has
`AdministratorAccess` attached because "it was easier at the time." There are four overlapping
security groups on the nodes from debugging sessions. Nobody knows which one to remove.
Upgrades are blocked because nobody is sure what the current state is. This is the cost of
ClickOps at the infrastructure layer — technical debt at the foundation of your entire platform.
Terraform-managed EKS means the cluster configuration is a file you can read, diff, and PR.

## What You'll Learn
- How to provision an EKS cluster and managed node group with Terraform
- What IAM roles are required — one for the control plane, a separate one for nodes
- Why the Kubernetes Terraform provider has a chicken-and-egg initialisation challenge
- How `aws eks update-kubeconfig` connects your local kubectl to the provisioned cluster
- The tradeoffs of EKS managed node groups vs self-managed nodes vs Fargate
- What IAM Roles for Service Accounts (IRSA) is and why it replaces node-level IAM permissions

## What Changed in This Class
- `terraform/eks-iam.tf` — two IAM roles (cluster + nodes) with minimal required policies
- `terraform/eks.tf` — aws_eks_cluster and aws_eks_node_group: t3.medium, 2–4 nodes, private subnets
- `terraform/kubernetes-provider.tf` — kubernetes provider configured from EKS cluster outputs
- `terraform/outputs.tf` — updated to include cluster_name, cluster_endpoint, kubeconfig_command
- `docs/eks-setup.md` — step-by-step guide from terraform apply to helm install
- `Makefile` — added eks-kubeconfig, eks-nodes, eks-cluster-info targets

## Concept Deep Dive

**EKS vs self-managed Kubernetes** — EKS manages the control plane (API server, etcd,
controller manager, scheduler) as a fully managed AWS service. You pay per cluster per hour
but get: automatic control plane upgrades (one click), built-in HA across 3 AZs, AWS-managed
etcd backups, and deep integration with IAM, VPC, and ALB. Self-managed K8s (using kubeadm on
EC2) gives you full control but requires you to manage etcd backups, control plane HA,
certificate rotation, and version upgrades manually. For production on AWS, EKS is the right
default unless you have very specific requirements (air-gapped, custom admission webhooks at
scale, non-AWS cloud).

**Managed node groups vs Fargate** — Managed node groups are EC2 instances managed by AWS
(AMI updates, draining, replacement). You see and pay for the EC2 instances. Fargate runs each
pod in an isolated microVM — no nodes to manage, pay per pod per second. Fargate is excellent
for batch jobs and variable workloads. For persistent web services, managed node groups give
better cost predictability and allow features Fargate does not support (DaemonSets,
hostNetwork, privileged containers, local NVMe storage).

**The Kubernetes provider chicken-and-egg problem** — The Terraform Kubernetes provider needs
the cluster endpoint and CA certificate to connect. These values only exist after
`aws_eks_cluster` is created. Terraform resolves this during a single apply by evaluating
the dependency graph: it creates the EKS cluster first, then uses its outputs to configure
the Kubernetes provider for subsequent resource creation. However, on the very first `init`
the provider cannot validate its configuration because the cluster does not exist yet.
In practice: always run `terraform apply` targeting EKS resources first, then apply the
Kubernetes resources in a second apply or the same apply with proper `depends_on` wiring.

## Hands-On Exercise
1. Run `terraform plan -var="environment=dev" -var="db_password=test"` and count the resources
2. After apply (takes 10–15 minutes for EKS):
   `terraform output kubeconfig_command` — copy and run the output
3. `kubectl get nodes` — wait for both nodes to show `Ready`
4. `kubectl cluster-info` — verify you're talking to the right cluster
5. Run `make eks-cluster-info`
6. Deploy the JCC application with Helm: `make helm-install`
7. Destroy when done: `terraform destroy -var="environment=dev" -var="db_password=test"`

## Common Mistakes
1. **Not separating cluster and node IAM roles** — The EKS service role and the node instance
   role have completely different trust policies and permissions. The cluster role is assumed
   by `eks.amazonaws.com`. The node role is assumed by `ec2.amazonaws.com`. Using one role for
   both produces confusing permission errors during node registration. Always create them as
   separate resources with separate `assume_role_policy` blocks.
2. **Provisioning nodes in public subnets** — Nodes in public subnets get public IP addresses
   and are directly reachable from the internet. Node ports and hostNetwork pods become
   internet-exposed. Always put worker nodes in private subnets. The control plane endpoint
   can remain public for developer kubectl access.
3. **Forgetting to re-init after changing Kubernetes provider config** — If you modify the
   `host` or `cluster_ca_certificate` in the kubernetes provider block and the cluster
   endpoint changes, Terraform cannot connect to apply Kubernetes resources until you run
   `terraform init -reconfigure`. This is a common source of "connection refused" errors that
   mislead engineers into thinking the cluster is down.

## You Have Completed the Full Stack

```
class-01   Plain HTML, no server                  <- where you started
class-05   Node.js + npm scripts + Makefile
class-08   Docker multi-stage builds
class-10   Docker Compose + PostgreSQL
class-14   CI/CD with GitHub Actions
class-17   Kubernetes Deployments, Services, Secrets
class-21   Rolling updates + HPA autoscaling
class-24   Jenkins full CD pipeline
class-25   Prometheus + Grafana monitoring
class-26   Helm chart packaging
class-27   RBAC least-privilege access
class-28   Zero-trust NetworkPolicies
class-29   PodDisruptionBudgets + PriorityClasses
class-30   External Secrets Operator
class-31   Terraform Infrastructure as Code
class-32   Terraform modules + remote state
class-33   Terraform provisions EKS cluster        <- where you are now
```

Every company running software at scale uses tools from this exact stack.
You now understand how all of them fit together, end to end.
