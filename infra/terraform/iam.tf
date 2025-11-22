locals {
  sanitized_cluster_name         = lower(replace(replace(var.cluster_name, "_", "-"), " ", "-"))
  sanitized_cluster_name_trimmed = trim(local.sanitized_cluster_name, "-")
  node_sa_base                   = local.sanitized_cluster_name_trimmed != "" ? local.sanitized_cluster_name_trimmed : "xmpp"
  node_sa_account_id             = substr(local.node_sa_base, 0, min(20, length(local.node_sa_base)))

  node_sa_roles = [
    "roles/artifactregistry.reader",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer"
  ]
}

resource "google_service_account" "node_pool" {
  account_id   = "gke-${local.node_sa_account_id}-np"
  display_name = "${var.cluster_name} node pool"
}

resource "google_project_iam_member" "node_sa_roles" {
  for_each = toset(local.node_sa_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.node_pool.email}"
}
