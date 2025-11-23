output "db_endpoint" {
  description = "Writer endpoint for the database."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port the database listens on."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Logical database name."
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Database user."
  value       = aws_db_instance.this.username
}

output "db_password" {
  description = "Generated database password."
  value       = random_password.db.result
  sensitive   = true
}

output "db_arn" {
  description = "ARN of the RDS instance."
  value       = aws_db_instance.this.arn
}

output "db_resource_id" {
  description = "RDS DB resource ID (used for IAM auth)."
  value       = aws_db_instance.this.resource_id
}

output "security_group_id" {
  description = "Security group protecting the database."
  value       = aws_security_group.this.id
}
