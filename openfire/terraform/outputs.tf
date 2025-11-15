output "openfire_db_connection_name" {
  description = "Cloud SQL connection string for the Openfire database."
  value       = google_sql_database_instance.openfire.connection_name
}

output "openfire_db_private_ip" {
  description = "Private IP address used by workloads inside the VPC."
  value       = google_sql_database_instance.openfire.private_ip_address
}

output "openfire_db_name" {
  description = "Logical PostgreSQL database name."
  value       = google_sql_database.openfire.name
}

output "openfire_db_user" {
  description = "Database user assigned to Openfire."
  value       = google_sql_user.openfire.name
}

output "openfire_db_password" {
  description = "Randomly generated password for the Openfire DB user."
  value       = random_password.openfire_db_user.result
  sensitive   = true
}

output "openfire_db_instance_self_link" {
  description = "Self link for the Cloud SQL instance (useful for debugging)."
  value       = google_sql_database_instance.openfire.self_link
}
