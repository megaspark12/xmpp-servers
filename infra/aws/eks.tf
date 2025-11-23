locals {
  api_public_cidrs      = length(var.api_allowed_cidrs) > 0 ? var.api_allowed_cidrs : ["0.0.0.0/0"]
  node_desired_capacity = max(var.node_pool_min_count, length(local.azs))
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.cluster_version

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids              = concat(values(aws_subnet.private)[*].id, values(aws_subnet.public)[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = local.api_public_cidrs
  }

  tags = merge(var.resource_tags, {
    Name = "${var.cluster_name}-eks"
  })

  depends_on = [aws_iam_role_policy_attachment.cluster_policies]
}

resource "aws_security_group" "nodes" {
  name        = "${var.cluster_name}-nodes"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow node to node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.resource_tags, {
    Name = "${var.cluster_name}-nodes"
  })
}

resource "aws_launch_template" "node" {
  name_prefix   = "${var.cluster_name}-node-"
  ebs_optimized = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size_gb
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [
      aws_security_group.nodes.id,
      aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
    ]
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.resource_tags, var.node_tags, {
      Name = "${var.cluster_name}-node"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.resource_tags, {
      Name = "${var.cluster_name}-node-volume"
    })
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_node_group" "primary" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = values(aws_subnet.private)[*].id
  capacity_type   = "ON_DEMAND"
  ami_type        = "AL2_x86_64"
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = local.node_desired_capacity
    min_size     = var.node_pool_min_count
    max_size     = var.node_pool_max_count
  }

  update_config {
    max_unavailable = 1
  }

  labels = merge({
    cluster  = var.cluster_name,
    workload = "xmpp"
  }, var.node_labels)

  launch_template {
    id      = aws_launch_template.node.id
    version = "$Latest"
  }

  tags = merge(var.resource_tags, {
    Name = "${var.cluster_name}-nodes"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_policies,
    aws_launch_template.node
  ]
}
