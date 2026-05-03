# EKS Cluster Setup with Terraform

## Prerequisites

- Terraform >= 1.5.0 installed
- AWS CLI v2 configured (`aws configure` or environment variables)
- IAM permissions: AmazonEKSFullAccess, AmazonEC2FullAccess, IAMFullAccess
- kubectl installed (version within 1 minor version of cluster)

## Step 1: Provision the Cluster

```bash
cd terraform

# Initialize providers
terraform init

# Preview — EKS creates ~15 resources including IAM roles, node group, VPC config
terraform plan \
  -var="environment=dev" \
  -var="db_password=${DB_PASSWORD}"

# Apply — EKS cluster creation takes 10–15 minutes
terraform apply \
  -var="environment=dev" \
  -var="db_password=${DB_PASSWORD}"
```

After apply you will see output like:
```
cluster_name      = "jcc-dev"
cluster_endpoint  = "https://ABCD1234.gr7.us-east-1.eks.amazonaws.com"
kubeconfig_command = "aws eks update-kubeconfig --region us-east-1 --name jcc-dev"
```

## Step 2: Configure kubectl

```bash
# Run the exact command from terraform output
aws eks update-kubeconfig --region us-east-1 --name jcc-dev

# Verify — nodes take ~3 minutes to reach Ready state after the cluster becomes Active
kubectl get nodes
# NAME                         STATUS   ROLES    AGE   VERSION
# ip-10-0-11-xx.ec2.internal   Ready    <none>   3m    v1.29.x
# ip-10-0-12-xx.ec2.internal   Ready    <none>   3m    v1.29.x
```

## Step 3: Verify and Deploy

```bash
kubectl cluster-info
# Kubernetes control plane is running at https://...eks.amazonaws.com

kubectl get namespaces
# default, kube-system, kube-public, kube-node-lease

# Now apply JCC application manifests (from earlier classes)
kubectl apply -f k8s/rbac/
kubectl apply -f k8s/network-policies/
kubectl apply -f k8s/reliability/

# Or use Helm (from class-26)
helm upgrade --install jcc ./helm/jcc-chart \
  --namespace jcc-production \
  --create-namespace \
  -f helm/jcc-chart/values-production.yaml \
  --set image.tag=$(git rev-parse --short HEAD)
```

## Step 4: Destroy When Done

```bash
# Removes cluster, node group, IAM roles, VPC, RDS — everything Terraform created
terraform destroy \
  -var="environment=dev" \
  -var="db_password=${DB_PASSWORD}"

# Re-apply creates identical infrastructure from scratch
terraform apply \
  -var="environment=dev" \
  -var="db_password=${DB_PASSWORD}"
```

## Key Configuration Details

| Setting | Value | Why |
|---------|-------|-----|
| Node type | t3.medium | Minimum practical size; t3.small OOMs under JCC workload |
| Node count | 2 min, 4 max | HA across 2 AZs; autoscaler can expand |
| Nodes in | private subnets | Not directly reachable from internet |
| Control plane | public endpoint | Required for `kubectl` from developer machines |
| K8s version | 1.29 | Supported version with 14-month AWS support window |
