variable "project_id" {
  description = "GCP project that will host the Cloud SQL instance."
  type        = string
}

variable "region" {
  description = "Region for the Cloud SQL instance."
  type        = string
}

variable "instance_name" {
  description = "Name of the Cloud SQL instance."
  type        = string
}

variable "database_version" {
  description = "PostgreSQL engine/version."
  type        = string
  default     = "POSTGRES_15"
}

variable "tier" {
  description = "Instance tier (db-custom-* for custom CPU/RAM)."
  type        = string
  default     = "db-custom-2-8192"
}

variable "disk_size_gb" {
  description = "Disk allocation for the instance."
  type        = number
  default     = 100
}

variable "disk_autoresize" {
  description = "Allow Cloud SQL to auto-grow the disk."
  type        = bool
  default     = true
}

variable "availability_type" {
  description = "REGIONAL or ZONAL."
  type        = string
  default     = "REGIONAL"
}

variable "backup_enabled" {
  description = "Enable automated backups."
  type        = bool
  default     = true
}

variable "pitr_enabled" {
  description = "Enable point-in-time recovery (requires backups)."
  type        = bool
  default     = true
}

variable "maintenance_window" {
  description = "Optional weekly maintenance window (day 1-7, hour 0-23)."
  type = object({
    day  = optional(number)
    hour = optional(number)
  })
  default = null
}

variable "deletion_protection" {
  description = "Protect the Cloud SQL instance from deletion."
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Logical database name."
  type        = string
}

variable "db_user" {
  description = "Database user."
  type        = string
}

variable "db_password_length" {
  description = "Length of the generated database password."
  type        = number
  default     = 24
}

variable "enable_private_ip" {
  description = "Use private IP (requires PSA connection on the target network)."
  type        = bool
  default     = true
}

variable "private_network_self_link" {
  description = "Self link of the VPC network to use for private IP."
  type        = string
  default     = ""

  validation {
    condition     = var.enable_private_ip ? var.private_network_self_link != "" : true
    error_message = "private_network_self_link must be set when enable_private_ip is true."
  }
}

variable "labels" {
  description = "User labels applied to the Cloud SQL instance."
  type        = map(string)
  default     = {}
}

variable "create_service_account" {
  description = "Create a GCP service account for clients (Workload Identity)."
  type        = bool
  default     = false
}

variable "service_account_id" {
  description = "Service account ID (without domain)."
  type        = string
  default     = ""
}

variable "service_account_roles" {
  description = "IAM roles granted to the service account."
  type        = list(string)
  default     = ["roles/cloudsql.client", "roles/cloudsql.instanceUser"]
}

variable "ksa_namespace" {
  description = "Kubernetes namespace for Workload Identity binding."
  type        = string
  default     = ""
}

variable "ksa_name" {
  description = "Kubernetes service account name for Workload Identity binding."
  type        = string
  default     = ""
}
