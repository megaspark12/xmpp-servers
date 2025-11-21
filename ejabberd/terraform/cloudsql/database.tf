resource "random_password" "ejabberd_db_user" {
  length           = var.db_password_length
  min_special      = 4
  override_special = "@_-+."
}

resource "google_sql_database_instance" "ejabberd" {
  name                = var.db_instance_name
  database_version    = var.db_database_version
  region              = var.region
  project             = var.project_id
  deletion_protection = var.db_deletion_protection

  depends_on = [
    google_project_service.apis["sqladmin.googleapis.com"],
    google_service_networking_connection.private_vpc_connection
  ]

  settings {
    tier              = var.db_tier
    availability_type = upper(var.db_availability_type)
    disk_autoresize   = var.db_disk_autoresize
    disk_size         = var.db_disk_size_gb
    disk_type         = "PD_SSD"

    backup_configuration {
      enabled                        = var.db_backup_enabled
      point_in_time_recovery_enabled = var.db_backup_enabled && var.db_pitr_enabled
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = data.google_compute_network.shared.self_link
      enable_private_path_for_google_cloud_services = true
    }

    insights_config {
      query_insights_enabled  = true
      record_application_tags = true
      record_client_address   = true
      query_string_length     = 1024
    }

    user_labels = {
      app     = "ejabberd"
      managed = "terraform"
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

resource "google_sql_database" "ejabberd" {
  name     = var.db_name
  instance = google_sql_database_instance.ejabberd.name
  project  = var.project_id
}

resource "google_sql_user" "ejabberd" {
  name     = var.db_user
  instance = google_sql_database_instance.ejabberd.name
  project  = var.project_id
  password = random_password.ejabberd_db_user.result
}
