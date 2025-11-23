data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.${data.aws_partition.current.dns_suffix}"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.resource_tags, {
    Name = "${var.cluster_name}-cluster"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policies" {
  for_each = toset([
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  ])

  role       = aws_iam_role.eks_cluster.name
  policy_arn = each.value
}

resource "aws_iam_role" "eks_node" {
  name = "${var.cluster_name}-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.${data.aws_partition.current.dns_suffix}"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.resource_tags, {
    Name = "${var.cluster_name}-node"
  })
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  role       = aws_iam_role.eks_node.name
  policy_arn = each.value
}

data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.this.name

  depends_on = [aws_eks_cluster.this]
}

data "tls_certificate" "oidc" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]

  tags = merge(var.resource_tags, {
    Name = "${var.cluster_name}-oidc"
  })
}
