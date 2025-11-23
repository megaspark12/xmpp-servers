output "sql_host" {
  description = "Primary IP address (private or public) of the Cloud SQL instance."
  value       = google_sql_database_instance.this.private_ip_address != "" ? google_sql_database_instance.this.private_ip_address : google_sql_database_instance.this.public_ip_address
}

output "sql_connection_name" {
  description = "Cloud SQL connection name."
  value       = google_sql_database_instance.this.connection_name
}

output "sql_database" {
  description = "Logical database name."
  value       = google_sql_database.this.name
}

output "sql_username" {
  description = "Database user."
  value       = google_sql_user.this.name
}

output "sql_password" {
  description = "Generated database password."
  value       = random_password.db_user.result
  sensitive   = true
}

output "service_account_email" {
  description = "Service account email for Workload Identity (if created)."
  value       = length(google_service_account.client) > 0 ? google_service_account.client[0].email : null
}
