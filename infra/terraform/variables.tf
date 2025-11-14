variable "project_id" {
  description = "ID of the Google Cloud project that will host the xmpp infrastructure."
  type        = string
}

variable "region" {
  description = "GCP region that will host the regional GKE control plane and node pools."
  type        = string
  default     = "europe-west1"
}

variable "cluster_name" {
  description = "Human-friendly name for the xmpp GKE cluster."
  type        = string
  default     = "xmpp-prod"
}

variable "network_name" {
  description = "Name of the dedicated VPC network for the xmpp workload."
  type        = string
  default     = "xmpp-prod-net"
}

variable "subnet_cidr" {
  description = "Primary CIDR block for the regional subnet that hosts the node pool."
  type        = string
  default     = "10.10.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary CIDR range dedicated to Kubernetes pods (VPC-native)."
  type        = string
  default     = "10.20.0.0/14"
}

variable "services_cidr" {
  description = "Secondary CIDR range dedicated to Kubernetes services (VPC-native)."
  type        = string
  default     = "10.40.0.0/20"
}

variable "pods_ip_range_name" {
  description = "Name given to the pod secondary range so the cluster can reference it."
  type        = string
  default     = "gke-pods"
}

variable "services_ip_range_name" {
  description = "Name given to the service secondary range so the cluster can reference it."
  type        = string
  default     = "gke-services"
}

variable "release_channel" {
  description = "GKE release channel to subscribe the control plane and node pool to."
  type        = string
  default     = "STABLE"
}

variable "node_machine_type" {
  description = "Machine type used for the primary node pool."
  type        = string
  default     = "e2-standard-4"
}

variable "node_image_type" {
  description = "Image that node pool VMs use."
  type        = string
  default     = "COS_CONTAINERD"
}

variable "node_disk_size_gb" {
  description = "Size (GB) of the boot disk attached to each node."
  type        = number
  default     = 150
}

variable "node_zones" {
  description = "Zones within the selected region that should host nodes for higher availability."
  type        = list(string)
  default     = [
    "europe-west1-b",
    "europe-west1-c",
    "europe-west1-d"
  ]
}

variable "node_pool_min_count" {
  description = "Minimum number of nodes that the autoscaler keeps in the pool."
  type        = number
  default     = 3
}

variable "node_pool_max_count" {
  description = "Maximum number of nodes that the autoscaler can scale the pool to."
  type        = number
  default     = 6
}

variable "node_tags" {
  description = "Network tags that will be propagated to each GKE node."
  type        = list(string)
  default     = ["gke", "xmpp"]
}

variable "node_labels" {
  description = "Additional Kubernetes node labels applied via GCE metadata."
  type        = map(string)
  default     = {
    "purpose" = "xmpp"
  }
}

variable "cluster_labels" {
  description = "Labels that describe the cluster resource in GCP."
  type        = map(string)
  default     = {
    "app"     = "xmpp",
    "env"     = "prod",
    "managed" = "terraform"
  }
}

variable "master_authorized_networks" {
  description = "CIDR blocks that are allowed to reach the public GKE control plane endpoint (set to your MacBook IP)."
  type = list(object({
    cidr_block   = string,
    display_name = optional(string)
  }))
  default = []
}

variable "default_max_pods_per_node" {
  description = "Upper bound on pods scheduled per node; keep this aligned with the selected CIDR ranges."
  type        = number
  default     = 110
}
