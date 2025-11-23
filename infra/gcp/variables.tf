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
  default = [
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
  default = {
    "purpose" = "xmpp"
  }
}

variable "cluster_labels" {
  description = "Labels that describe the cluster resource in GCP."
  type        = map(string)
  default = {
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

variable "enable_ejabberd_cloudsql" {
  description = "Set to true to provision a Cloud SQL instance for ejabberd."
  type        = bool
  default     = false
}

variable "enable_openfire_cloudsql" {
  description = "Set to true to provision a Cloud SQL instance for openfire."
  type        = bool
  default     = false
}

variable "cloudsql_use_private_ip" {
  description = "Use private IP for Cloud SQL (requires Private Service Access on the network)."
  type        = bool
  default     = true
}

variable "cloudsql_create_psa" {
  description = "Create the Private Service Access reserved range and connection automatically. Disable if an existing connection already exists."
  type        = bool
  default     = false
}

variable "cloudsql_psa_cidr" {
  description = "CIDR block reserved for Private Service Access when cloudsql_create_psa is true."
  type        = string
  default     = "10.60.0.0/24"
}

variable "cloudsql_psa_range_name" {
  description = "Name of the reserved PSA range used for Cloud SQL."
  type        = string
  default     = "xmpp-sql-private"
}

variable "ejabberd_sql_instance_name" {
  description = "Cloud SQL instance name for ejabberd."
  type        = string
  default     = "ejabberd-sql"
}

variable "ejabberd_sql_db_name" {
  description = "Logical database name for ejabberd."
  type        = string
  default     = "ejabberd"
}

variable "ejabberd_sql_db_user" {
  description = "Database user for ejabberd."
  type        = string
  default     = "ejabberd_app"
}

variable "ejabberd_sql_tier" {
  description = "Cloud SQL tier for ejabberd."
  type        = string
  default     = "db-custom-2-8192"
}

variable "ejabberd_sql_disk_size_gb" {
  description = "Disk allocation (GB) for the ejabberd database."
  type        = number
  default     = 100
}

variable "ejabberd_sql_backup_enabled" {
  description = "Enable automated backups for ejabberd."
  type        = bool
  default     = true
}

variable "ejabberd_sql_pitr_enabled" {
  description = "Enable point-in-time recovery for ejabberd."
  type        = bool
  default     = true
}

variable "ejabberd_sql_deletion_protection" {
  description = "Protect the ejabberd Cloud SQL instance from deletion."
  type        = bool
  default     = true
}

variable "ejabberd_sql_maintenance_window" {
  description = "Optional weekly maintenance window for ejabberd (day 1-7, hour 0-23)."
  type = object({
    day  = optional(number)
    hour = optional(number)
  })
  default = null
}

variable "openfire_sql_instance_name" {
  description = "Cloud SQL instance name for openfire."
  type        = string
  default     = "openfire-sql"
}

variable "openfire_sql_db_name" {
  description = "Logical database name for openfire."
  type        = string
  default     = "openfire"
}

variable "openfire_sql_db_user" {
  description = "Database user for openfire."
  type        = string
  default     = "openfire_app"
}

variable "openfire_sql_tier" {
  description = "Cloud SQL tier for openfire."
  type        = string
  default     = "db-custom-2-8192"
}

variable "openfire_sql_disk_size_gb" {
  description = "Disk allocation (GB) for the openfire database."
  type        = number
  default     = 100
}

variable "openfire_sql_backup_enabled" {
  description = "Enable automated backups for openfire."
  type        = bool
  default     = true
}

variable "openfire_sql_pitr_enabled" {
  description = "Enable point-in-time recovery for openfire."
  type        = bool
  default     = true
}

variable "openfire_sql_deletion_protection" {
  description = "Protect the openfire Cloud SQL instance from deletion."
  type        = bool
  default     = true
}

variable "openfire_sql_maintenance_window" {
  description = "Optional weekly maintenance window for openfire (day 1-7, hour 0-23)."
  type = object({
    day  = optional(number)
    hour = optional(number)
  })
  default = null
}

variable "openfire_sql_service_account_id" {
  description = "Service account ID (without domain) for openfire Cloud SQL access."
  type        = string
  default     = "openfire-sql-client"
}

variable "openfire_ksa_namespace" {
  description = "Kubernetes namespace for the openfire Workload Identity binding."
  type        = string
  default     = "openfire"
}

variable "openfire_ksa_name" {
  description = "Kubernetes service account name for the openfire Workload Identity binding."
  type        = string
  default     = "openfire"
}
