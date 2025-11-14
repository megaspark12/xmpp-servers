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
