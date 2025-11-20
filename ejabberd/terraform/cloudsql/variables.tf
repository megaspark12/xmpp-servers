variable "project_id" {
  description = "GCP project ID hosting Cloud SQL and the GKE cluster."
  type        = string
}

variable "region" {
  description = "GCP region for the Cloud SQL instance (match the GKE region for lower latency)."
  type        = string
  default     = "europe-west1"
}

variable "instance_name" {
  description = "Name of the Cloud SQL instance."
  type        = string
  default     = "ejabberd-sql"
}

variable "database_name" {
  description = "Name of the application database."
  type        = string
  default     = "ejabberd"
}

variable "db_version" {
  description = "Cloud SQL engine/version."
  type        = string
  default     = "POSTGRES_15"
}

variable "tier" {
  description = "Instance machine tier, e.g. db-custom-2-7680."
  type        = string
  default     = "db-custom-2-7680"
}

variable "availability_type" {
  description = "Cloud SQL availability class (ZONAL or REGIONAL)."
  type        = string
  default     = "REGIONAL"
}

variable "disk_size" {
  description = "Disk size in GB."
  type        = number
  default     = 50
}

variable "deletion_protection" {
  description = "Protect the Cloud SQL instance from accidental deletion."
  type        = bool
  default     = true
}

variable "enable_pitr" {
  description = "Enable point-in-time recovery."
  type        = bool
  default     = true
}

variable "vpc_network" {
  description = "Self link of the VPC network for private IP (e.g. projects/your-project/global/networks/default)."
  type        = string
}

variable "private_ip_range_name" {
  description = "Name for the allocated private service connection range."
  type        = string
  default     = "ejabberd-sql-range"
}

variable "private_ip_range_prefix_length" {
  description = "CIDR prefix length for the PSC range."
  type        = number
  default     = 20
}

variable "kubernetes_namespace" {
  description = "Namespace where ejabberd runs and where DB secrets will be created."
  type        = string
  default     = "ejabberd"
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file for the cluster."
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Optional kubeconfig context name; leave empty to use the default."
  type        = string
  default     = ""
}

variable "db_user" {
  description = "Database user for ejabberd."
  type        = string
  default     = "ejabberd_app"
}
