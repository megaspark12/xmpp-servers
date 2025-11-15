resource "google_service_account" "openfire_sql" {
  account_id   = var.gcp_service_account_id
  display_name = "Openfire Cloud SQL client"
  project      = var.project_id
}

resource "google_project_iam_member" "openfire_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.openfire_sql.email}"
}

resource "google_project_iam_member" "openfire_sql_instance_user" {
  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:${google_service_account.openfire_sql.email}"
}

resource "google_service_account_iam_member" "wia_binding" {
  service_account_id = google_service_account.openfire_sql.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.ksa_namespace}/${var.ksa_name}]"
}
