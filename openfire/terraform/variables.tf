variable "project_id" {
  description = "GCP project that hosts the shared network and Cloud SQL instance."
  type        = string
}

variable "region" {
  description = "Region where the Cloud SQL instance and its failover replica will run."
  type        = string
  default     = "europe-west1"
}

variable "gcp_service_account_id" {
  description = "Service account ID (without domain) used by GKE workloads to access Cloud SQL."
  type        = string
  default     = "openfire-sql-client"
}

variable "ksa_namespace" {
  description = "Namespace of the Kubernetes service account that will run Openfire."
  type        = string
  default     = "openfire"
}

variable "ksa_name" {
  description = "Name of the Kubernetes service account that will assume the Workload Identity binding."
  type        = string
  default     = "openfire"
}

variable "db_instance_name" {
  description = "Name given to the Cloud SQL instance."
  type        = string
  default     = "openfire-sql"
}

variable "db_database_version" {
  description = "PostgreSQL engine version for Cloud SQL."
  type        = string
  default     = "POSTGRES_15"
}

variable "db_tier" {
  description = "Cloud SQL tier (use db-custom-* for custom CPU/RAM)."
  type        = string
  default     = "db-custom-2-8192"
}

variable "db_disk_size_gb" {
  description = "Disk allocation for the Cloud SQL instance."
  type        = number
  default     = 100
}

variable "db_disk_autoresize" {
  description = "Allow Cloud SQL to auto-grow the primary disk."
  type        = bool
  default     = true
}

variable "db_availability_type" {
  description = "Either REGIONAL (HA) or ZONAL."
  type        = string
  default     = "REGIONAL"
}

variable "db_backup_enabled" {
  description = "Enable automated backups and PITR."
  type        = bool
  default     = true
}

variable "db_maintenance_window" {
  description = "Optional weekly maintenance window (day 1-7, hour 0-23)."
  type = object({
    day  = optional(number)
    hour = optional(number)
  })
  default = null
}

variable "db_name" {
  description = "Logical PostgreSQL database dedicated to Openfire."
  type        = string
  default     = "openfire"
}

variable "db_user" {
  description = "PostgreSQL user that Openfire uses."
  type        = string
  default     = "openfire_app"
}

variable "db_password_length" {
  description = "Length of the randomly generated Openfire DB password."
  type        = number
  default     = 24
}

variable "db_deletion_protection" {
  description = "Prevent Terraform from destroying the Cloud SQL instance."
  type        = bool
  default     = false
}
