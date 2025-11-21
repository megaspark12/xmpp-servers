variable "project_id" {
  description = "GCP project that hosts the shared network and ejabberd Cloud SQL instance."
  type        = string
}

variable "region" {
  description = "Region where the Cloud SQL primary and failover replica run."
  type        = string
  default     = "europe-west1"
}

variable "network_name" {
  description = "Existing VPC network to peer with for private IP connectivity (created by infra/terraform)."
  type        = string
  default     = "xmpp-prod-net"
}

variable "private_service_cidr" {
  description = "CIDR (between /16-/29) reserved for Private Service Access; must not overlap with cluster or service ranges."
  type        = string
  default     = "10.60.0.0/24"

  validation {
    condition     = can(cidrnetmask(var.private_service_cidr)) && tonumber(split("/", var.private_service_cidr)[1]) >= 16 && tonumber(split("/", var.private_service_cidr)[1]) <= 29
    error_message = "private_service_cidr must be a valid CIDR within /16-/29."
  }
}

variable "db_instance_name" {
  description = "Name of the Cloud SQL instance."
  type        = string
  default     = "ejabberd-sql"
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

  validation {
    condition     = contains(["REGIONAL", "ZONAL"], upper(var.db_availability_type))
    error_message = "db_availability_type must be REGIONAL or ZONAL."
  }
}

variable "db_backup_enabled" {
  description = "Enable automated backups."
  type        = bool
  default     = true
}

variable "db_pitr_enabled" {
  description = "Enable point-in-time recovery (requires backups)."
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

variable "db_deletion_protection" {
  description = "Prevent Terraform from destroying the Cloud SQL instance."
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Logical PostgreSQL database dedicated to ejabberd."
  type        = string
  default     = "ejabberd"
}

variable "db_user" {
  description = "PostgreSQL user that ejabberd uses."
  type        = string
  default     = "ejabberd_app"
}

variable "db_password_length" {
  description = "Length of the randomly generated ejabberd DB password."
  type        = number
  default     = 24
}
