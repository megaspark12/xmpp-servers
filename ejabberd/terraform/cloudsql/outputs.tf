output "sql_host" {
  description = "Private IP address of the Cloud SQL instance."
  value       = google_sql_database_instance.ejabberd.private_ip_address
}

output "sql_database" {
  description = "Database name for ejabberd."
  value       = google_sql_database.ejabberd.name
}

output "sql_username" {
  description = "Database user for ejabberd."
  value       = google_sql_user.ejabberd.name
}

output "sql_password" {
  description = "Database password for ejabberd."
  value       = random_password.db.result
  sensitive   = true
}

output "kubernetes_secret_name" {
  description = "Kubernetes secret containing SQL connection info."
  value       = kubernetes_secret.ejabberd_sql.metadata[0].name
}
