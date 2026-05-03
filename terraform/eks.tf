resource "aws_eks_cluster" "main" {
  name     = "${var.app_name}-${var.environment}"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    # In production consider restricting public_access_cidrs to your office/VPN CIDR ranges.
    # public_access_cidrs = ["203.0.113.0/32"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]

  tags = {
    Name = "${var.app_name}-${var.environment}-cluster"
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.app_name}-${var.environment}-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn

  # Nodes in private subnets only — not directly reachable from the internet.
  subnet_ids = aws_subnet.private[*].id

  instance_types = ["t3.medium"]   # 2 vCPU, 4GB RAM — minimum for real workloads

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  update_config {
    max_unavailable = 1   # rolling node updates: one node at a time
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_read_only,
  ]

  tags = {
    Name = "${var.app_name}-${var.environment}-node-group"
  }
}
