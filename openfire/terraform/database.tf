resource "google_project_service" "openfire" {
  for_each = toset([
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com"
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "random_password" "openfire_db_user" {
  length           = var.db_password_length
  min_special      = 4
  override_special = "@_-+."
}

resource "google_sql_database_instance" "openfire" {
  name                = var.db_instance_name
  database_version    = var.db_database_version
  region              = var.region
  project             = var.project_id
  deletion_protection = var.db_deletion_protection

  depends_on = [
    google_project_service.openfire["servicenetworking.googleapis.com"],
    google_project_service.openfire["sqladmin.googleapis.com"]
  ]

  settings {
    tier              = var.db_tier
    availability_type = var.db_availability_type
    disk_autoresize   = var.db_disk_autoresize
    disk_size         = var.db_disk_size_gb
    disk_type         = "PD_SSD"

    backup_configuration {
      enabled                        = var.db_backup_enabled
      point_in_time_recovery_enabled = var.db_backup_enabled
    }

    ip_configuration {
      ipv4_enabled = true
    }

    insights_config {
      query_insights_enabled  = true
      record_application_tags = true
      record_client_address   = true
      query_string_length     = 1024
    }

    dynamic "maintenance_window" {
      for_each = var.db_maintenance_window == null ? [] : [var.db_maintenance_window]
      content {
        day  = maintenance_window.value.day
        hour = maintenance_window.value.hour
      }
    }
  }
}

resource "google_sql_database" "openfire" {
  name     = var.db_name
  instance = google_sql_database_instance.openfire.name
  project  = var.project_id
}

resource "google_sql_user" "openfire" {
  name     = var.db_user
  instance = google_sql_database_instance.openfire.name
  project  = var.project_id
  password = random_password.openfire_db_user.result
}
