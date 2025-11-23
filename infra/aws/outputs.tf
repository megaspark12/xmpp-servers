output "cluster_name" {
  description = "Name of the provisioned xmpp EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_region" {
  description = "Region hosting the EKS control plane and node group."
  value       = var.region
}

output "vpc_id" {
  description = "Dedicated VPC backing the cluster."
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs that host worker nodes."
  value       = values(aws_subnet.private)[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs that host NAT gateways and load balancers."
  value       = values(aws_subnet.public)[*].id
}

output "eks_update_kubeconfig_command" {
  description = "Helper command to pull kubeconfig for the cluster."
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region ${var.region}"
}

output "cluster_oidc_provider_arn" {
  description = "IAM OIDC provider ARN used for IRSA."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "ejabberd_rds_endpoint" {
  description = "Endpoint for the ejabberd RDS instance."
  value       = try(module.ejabberd_rds[0].db_endpoint, null)
}

output "ejabberd_rds_database" {
  description = "Database name for ejabberd."
  value       = try(module.ejabberd_rds[0].db_name, null)
}

output "ejabberd_rds_username" {
  description = "Database user for ejabberd."
  value       = try(module.ejabberd_rds[0].db_username, null)
}

output "ejabberd_rds_password" {
  description = "Generated password for ejabberd."
  value       = try(module.ejabberd_rds[0].db_password, null)
  sensitive   = true
}

output "ejabberd_rds_port" {
  description = "Port for the ejabberd database."
  value       = try(module.ejabberd_rds[0].db_port, null)
}

output "openfire_rds_endpoint" {
  description = "Endpoint for the openfire RDS instance."
  value       = try(module.openfire_rds[0].db_endpoint, null)
}

output "openfire_rds_database" {
  description = "Database name for openfire."
  value       = try(module.openfire_rds[0].db_name, null)
}

output "openfire_rds_username" {
  description = "Database user for openfire."
  value       = try(module.openfire_rds[0].db_username, null)
}

output "openfire_rds_password" {
  description = "Generated password for openfire."
  value       = try(module.openfire_rds[0].db_password, null)
  sensitive   = true
}

output "openfire_rds_port" {
  description = "Port for the openfire database."
  value       = try(module.openfire_rds[0].db_port, null)
}

output "openfire_irsa_role_arn" {
  description = "IAM role ARN bound to the openfire service account (if created)."
  value       = local.openfire_irsa_enabled ? aws_iam_role.openfire_irsa[0].arn : null
}
