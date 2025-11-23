variable "identifier" {
  description = "Identifier for the RDS instance."
  type        = string
}

variable "db_name" {
  description = "Logical database name."
  type        = string
}

variable "username" {
  description = "Database master username."
  type        = string
}

variable "password_length" {
  description = "Length of the generated database password."
  type        = number
  default     = 24
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "15.5"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.m6i.large"
}

variable "allocated_storage" {
  description = "Initial storage allocation (GB)."
  type        = number
  default     = 100
}

variable "max_allocated_storage" {
  description = "Optional storage autoscaling ceiling (GB). Set 0 to disable."
  type        = number
  default     = 0
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 7
}

variable "maintenance_window" {
  description = "Optional weekly maintenance window (e.g., Sun:05:00-Sun:06:00)."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Protect the RDS instance from deletion."
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights."
  type        = bool
  default     = true
}

variable "enable_iam_auth" {
  description = "Enable IAM database authentication."
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID that hosts the database."
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the database on 5432."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to resources created by this module."
  type        = map(string)
  default     = {}
}
