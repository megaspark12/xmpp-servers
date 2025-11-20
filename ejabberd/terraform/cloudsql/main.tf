provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

resource "random_password" "db" {
  length  = 32
  special = false
}

# Allocate a private service connection range for Cloud SQL.
resource "google_compute_global_address" "private_ip_range" {
  name          = var.private_ip_range_name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  network       = var.vpc_network
  prefix_length = var.private_ip_range_prefix_length
}

# Connect the VPC to Google-managed services for private IP.
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_sql_database_instance" "ejabberd" {
  name                = var.instance_name
  database_version    = var.db_version
  region              = var.region
  deletion_protection = var.deletion_protection
  depends_on          = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_type         = "PD_SSD"
    disk_size         = var.disk_size

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = var.enable_pitr
    }

    maintenance_window {
      day          = 1 # Monday
      hour         = 4 # 04:00 UTC
      update_track = "stable"
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.vpc_network
      enable_private_path_for_google_cloud_services = true
    }
  }
}

resource "google_sql_database" "ejabberd" {
  name     = var.database_name
  instance = google_sql_database_instance.ejabberd.name
}

resource "google_sql_user" "ejabberd" {
  name     = var.db_user
  instance = google_sql_database_instance.ejabberd.name
  password = random_password.db.result
}

resource "kubernetes_secret" "ejabberd_sql" {
  metadata {
    name      = "ejabberd-sql"
    namespace = var.kubernetes_namespace
  }

  data = {
    sql_type     = "pgsql"
    sql_server   = google_sql_database_instance.ejabberd.private_ip_address
    sql_port     = "5432"
    sql_database = google_sql_database.ejabberd.name
    sql_username = google_sql_user.ejabberd.name
    sql_password = random_password.db.result
  }

  type = "Opaque"
}
