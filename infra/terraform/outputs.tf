output "cluster_name" {
  description = "Name of the provisioned xmpp GKE cluster."
  value       = google_container_cluster.primary.name
}

output "cluster_region" {
  description = "Region that is hosting the regional control plane and node pools."
  value       = google_container_cluster.primary.location
}

output "network_name" {
  description = "Dedicated VPC network backing the cluster."
  value       = google_compute_network.gke.name
}

output "subnet_name" {
  description = "Subnetwork used by the GKE node pool."
  value       = google_compute_subnetwork.gke.name
}

output "gcloud_get_credentials_command" {
  description = "Helper command that retrieves cluster credentials onto your workstation."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id}"
}

output "ejabberd_sql_host" {
  description = "Private IP (or public if configured) of the ejabberd Cloud SQL instance."
  value       = try(module.ejabberd_cloudsql[0].sql_host, null)
}

output "ejabberd_sql_database" {
  description = "Logical database name for ejabberd."
  value       = try(module.ejabberd_cloudsql[0].sql_database, null)
}

output "ejabberd_sql_username" {
  description = "Database user for ejabberd."
  value       = try(module.ejabberd_cloudsql[0].sql_username, null)
}

output "ejabberd_sql_password" {
  description = "Generated database password for ejabberd."
  value       = try(module.ejabberd_cloudsql[0].sql_password, null)
  sensitive   = true
}

output "ejabberd_sql_connection_name" {
  description = "Connection name for the ejabberd Cloud SQL instance."
  value       = try(module.ejabberd_cloudsql[0].sql_connection_name, null)
}

output "openfire_sql_host" {
  description = "Private IP (or public if configured) of the openfire Cloud SQL instance."
  value       = try(module.openfire_cloudsql[0].sql_host, null)
}

output "openfire_sql_database" {
  description = "Logical database name for openfire."
  value       = try(module.openfire_cloudsql[0].sql_database, null)
}

output "openfire_sql_username" {
  description = "Database user for openfire."
  value       = try(module.openfire_cloudsql[0].sql_username, null)
}

output "openfire_sql_password" {
  description = "Generated database password for openfire."
  value       = try(module.openfire_cloudsql[0].sql_password, null)
  sensitive   = true
}

output "openfire_sql_connection_name" {
  description = "Connection name for the openfire Cloud SQL instance."
  value       = try(module.openfire_cloudsql[0].sql_connection_name, null)
}

output "openfire_cloudsql_service_account" {
  description = "Service account email used by openfire to reach Cloud SQL (Workload Identity)."
  value       = try(module.openfire_cloudsql[0].service_account_email, null)
}

output "cloudsql_psa_range" {
  description = "Private Service Access CIDR reserved for Cloud SQL (if created)."
  value       = var.cloudsql_psa_cidr
}
