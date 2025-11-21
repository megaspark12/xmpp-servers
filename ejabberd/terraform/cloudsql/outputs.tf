output "sql_host" {
  description = "Private IP address of the ejabberd Cloud SQL instance."
  value       = google_sql_database_instance.ejabberd.private_ip_address
}

output "sql_database" {
  description = "Logical PostgreSQL database name."
  value       = google_sql_database.ejabberd.name
}

output "sql_username" {
  description = "Database user assigned to ejabberd."
  value       = google_sql_user.ejabberd.name
}

output "sql_password" {
  description = "Randomly generated password for the ejabberd DB user."
  value       = random_password.ejabberd_db_user.result
  sensitive   = true
}

output "sql_connection_name" {
  description = "Cloud SQL connection name (for debugging or proxy sidecars)."
  value       = google_sql_database_instance.ejabberd.connection_name
}

output "private_service_cidr" {
  description = "CIDR reserved for the Private Service Access peering."
  value       = var.private_service_cidr
}
