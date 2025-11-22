locals {
  cloudsql_enabled = var.enable_ejabberd_cloudsql || var.enable_openfire_cloudsql
  cloudsql_private = local.cloudsql_enabled && var.cloudsql_use_private_ip

  cloudsql_psa_prefix_length = tonumber(split("/", var.cloudsql_psa_cidr)[1])
  cloudsql_psa_address       = cidrhost(var.cloudsql_psa_cidr, 0)
}

resource "google_project_service" "cloudsql_apis" {
  for_each = local.cloudsql_enabled ? toset([
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com"
  ]) : toset([])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_global_address" "cloudsql_psa" {
  count = local.cloudsql_private && var.cloudsql_create_psa ? 1 : 0

  name          = var.cloudsql_psa_range_name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = local.cloudsql_psa_address
  prefix_length = local.cloudsql_psa_prefix_length
  network       = google_compute_network.gke.self_link

  depends_on = [
    google_project_service.cloudsql_apis
  ]
}

resource "google_service_networking_connection" "cloudsql" {
  count = local.cloudsql_private && var.cloudsql_create_psa ? 1 : 0

  network                 = google_compute_network.gke.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.cloudsql_psa[0].name]

  depends_on = [
    google_compute_global_address.cloudsql_psa
  ]
}

module "ejabberd_cloudsql" {
  count = var.enable_ejabberd_cloudsql ? 1 : 0

  source = "./modules/cloudsql_postgres"

  project_id    = var.project_id
  region        = var.region
  instance_name = var.ejabberd_sql_instance_name

  database_version    = "POSTGRES_15"
  tier                = var.ejabberd_sql_tier
  disk_size_gb        = var.ejabberd_sql_disk_size_gb
  disk_autoresize     = true
  availability_type   = "REGIONAL"
  backup_enabled      = var.ejabberd_sql_backup_enabled
  pitr_enabled        = var.ejabberd_sql_pitr_enabled
  maintenance_window  = var.ejabberd_sql_maintenance_window
  deletion_protection = var.ejabberd_sql_deletion_protection

  db_name            = var.ejabberd_sql_db_name
  db_user            = var.ejabberd_sql_db_user
  db_password_length = 24

  enable_private_ip         = var.cloudsql_use_private_ip
  private_network_self_link = google_compute_network.gke.self_link
  labels = {
    app     = "ejabberd"
    managed = "terraform"
  }

  create_service_account = false

  depends_on = [
    google_project_service.cloudsql_apis,
    google_service_networking_connection.cloudsql
  ]
}

module "openfire_cloudsql" {
  count = var.enable_openfire_cloudsql ? 1 : 0

  source = "./modules/cloudsql_postgres"

  project_id    = var.project_id
  region        = var.region
  instance_name = var.openfire_sql_instance_name

  database_version    = "POSTGRES_15"
  tier                = var.openfire_sql_tier
  disk_size_gb        = var.openfire_sql_disk_size_gb
  disk_autoresize     = true
  availability_type   = "REGIONAL"
  backup_enabled      = var.openfire_sql_backup_enabled
  pitr_enabled        = var.openfire_sql_pitr_enabled
  maintenance_window  = var.openfire_sql_maintenance_window
  deletion_protection = var.openfire_sql_deletion_protection

  db_name            = var.openfire_sql_db_name
  db_user            = var.openfire_sql_db_user
  db_password_length = 24

  enable_private_ip         = var.cloudsql_use_private_ip
  private_network_self_link = google_compute_network.gke.self_link
  labels = {
    app     = "openfire"
    managed = "terraform"
  }

  create_service_account = true
  service_account_id     = var.openfire_sql_service_account_id
  service_account_roles  = ["roles/cloudsql.client", "roles/cloudsql.instanceUser"]
  ksa_namespace          = var.openfire_ksa_namespace
  ksa_name               = var.openfire_ksa_name

  depends_on = [
    google_project_service.cloudsql_apis,
    google_service_networking_connection.cloudsql
  ]
}
