resource "random_password" "db_user" {
  length           = var.db_password_length
  min_special      = 4
  override_special = "@_-+."
}

resource "google_service_account" "client" {
  count = var.create_service_account ? 1 : 0

  account_id   = var.service_account_id
  display_name = "${var.instance_name} client"
  project      = var.project_id
}

resource "google_project_iam_member" "client_roles" {
  for_each = var.create_service_account ? toset(var.service_account_roles) : []

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.client[0].email}"
}

resource "google_service_account_iam_member" "wia_binding" {
  count = var.create_service_account && var.ksa_namespace != "" && var.ksa_name != "" ? 1 : 0

  service_account_id = google_service_account.client[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.ksa_namespace}/${var.ksa_name}]"
}

resource "google_sql_database_instance" "this" {
  name                = var.instance_name
  database_version    = var.database_version
  region              = var.region
  project             = var.project_id
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = upper(var.availability_type)
    disk_autoresize   = var.disk_autoresize
    disk_size         = var.disk_size_gb
    disk_type         = "PD_SSD"

    backup_configuration {
      enabled                        = var.backup_enabled
      point_in_time_recovery_enabled = var.backup_enabled && var.pitr_enabled
    }

    ip_configuration {
      ipv4_enabled                                  = !var.enable_private_ip
      private_network                               = var.enable_private_ip ? var.private_network_self_link : null
      enable_private_path_for_google_cloud_services = var.enable_private_ip
    }

    insights_config {
      query_insights_enabled  = true
      record_application_tags = true
      record_client_address   = true
      query_string_length     = 1024
    }

    user_labels = var.labels

    dynamic "maintenance_window" {
      for_each = var.maintenance_window == null ? [] : [var.maintenance_window]
      content {
        day  = maintenance_window.value.day
        hour = maintenance_window.value.hour
      }
    }
  }
}

resource "google_sql_database" "this" {
  name     = var.db_name
  instance = google_sql_database_instance.this.name
  project  = var.project_id
}

resource "google_sql_user" "this" {
  name     = var.db_user
  instance = google_sql_database_instance.this.name
  project  = var.project_id
  password = random_password.db_user.result
}
