# Kubernetes provider configuration — uses EKS cluster outputs for authentication.
# This is the chicken-and-egg problem in Terraform: the kubernetes provider needs
# the cluster endpoint and CA certificate to connect, but those only exist after
# aws_eks_cluster is created. Terraform handles this via depends_on and the
# data source, but it means the kubernetes provider cannot be configured until
# the EKS apply has completed at least once.

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}
