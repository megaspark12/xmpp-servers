locals {
  private_service_prefix  = tonumber(split("/", var.private_service_cidr)[1])
  private_service_address = cidrhost(var.private_service_cidr, 0)
}

data "google_compute_network" "shared" {
  name    = var.network_name
  project = var.project_id
}

resource "google_project_service" "apis" {
  for_each = toset([
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com"
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_global_address" "private_service_range" {
  name          = "${var.db_instance_name}-psa"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = local.private_service_address
  prefix_length = local.private_service_prefix
  network       = data.google_compute_network.shared.self_link

  depends_on = [
    google_project_service.apis["servicenetworking.googleapis.com"]
  ]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.google_compute_network.shared.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]

  depends_on = [
    google_project_service.apis["servicenetworking.googleapis.com"],
    google_compute_global_address.private_service_range
  ]
}
