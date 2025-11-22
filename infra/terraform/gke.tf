locals {
  node_pool_initial_nodes_per_zone = max(
    1,
    ceil(var.node_pool_min_count / max(1, length(var.node_zones)))
  )
}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  network    = google_compute_network.gke.self_link
  subnetwork = google_compute_subnetwork.gke.self_link

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = var.release_channel
  }

  networking_mode   = "VPC_NATIVE"
  datapath_provider = "ADVANCED_DATAPATH"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_ip_range_name
    services_secondary_range_name = var.services_ip_range_name
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "APISERVER", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "APISERVER"]
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  vertical_pod_autoscaling {
    enabled = true
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []

    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks

        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = try(cidr_blocks.value.display_name, null)
        }
      }
    }
  }

  resource_labels = var.cluster_labels

  enable_shielded_nodes     = true
  default_max_pods_per_node = var.default_max_pods_per_node

  depends_on = [
    google_project_service.enabled,
    google_compute_router_nat.gke
  ]
}

resource "google_container_node_pool" "primary" {
  name     = "${var.cluster_name}-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name

  initial_node_count = local.node_pool_initial_nodes_per_zone

  node_locations = var.node_zones

  autoscaling {
    min_node_count = var.node_pool_min_count
    max_node_count = var.node_pool_max_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible     = false
    machine_type    = var.node_machine_type
    image_type      = var.node_image_type
    disk_type       = "pd-balanced"
    disk_size_gb    = var.node_disk_size_gb
    service_account = google_service_account.node_pool.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    tags = var.node_tags
    labels = merge({
      "cluster"  = var.cluster_name,
      "workload" = "xmpp"
    }, var.node_labels)

    metadata = {
      disable-legacy-endpoints = "true"
    }

    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  depends_on = [
    google_container_cluster.primary
  ]
}
