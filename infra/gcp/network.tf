resource "google_compute_network" "gke" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "gke" {
  name          = "${var.network_name}-${var.region}"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.gke.id

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.pods_ip_range_name
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = var.services_ip_range_name
    ip_cidr_range = var.services_cidr
  }
}

resource "google_compute_router" "gke" {
  name    = "${var.cluster_name}-router"
  region  = var.region
  network = google_compute_network.gke.id
}

resource "google_compute_router_nat" "gke" {
  name                               = "${var.cluster_name}-nat"
  region                             = var.region
  router                             = google_compute_router.gke.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.gke.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
