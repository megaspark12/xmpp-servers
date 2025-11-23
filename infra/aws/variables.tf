variable "region" {
  description = "AWS region that will host the EKS control plane and node groups."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Human-friendly name for the xmpp EKS cluster."
  type        = string
  default     = "xmpp-prod"
}

variable "cluster_version" {
  description = "EKS control plane version."
  type        = string
  default     = "1.30"
}

variable "availability_zones" {
  description = "AZs to spread the cluster across. When empty, the first three AZs in the region are used."
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC."
  type        = string
  default     = "10.10.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets that host worker nodes (one per AZ)."
  type        = list(string)
  default = [
    "10.10.0.0/19",
    "10.10.32.0/19",
    "10.10.64.0/19"
  ]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per AZ) that host NAT gateways and optional load balancers."
  type        = list(string)
  default = [
    "10.10.128.0/20",
    "10.10.144.0/20",
    "10.10.160.0/20"
  ]
}

variable "api_allowed_cidrs" {
  description = "CIDR blocks permitted to reach the public EKS API endpoint (use your MacBook /32). Defaults to open if empty."
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "Instance families used by the primary node group."
  type        = list(string)
  default     = ["m6a.xlarge"]
}

variable "node_disk_size_gb" {
  description = "Size (GB) of the root volume for each node."
  type        = number
  default     = 150
}

variable "node_pool_min_count" {
  description = "Minimum number of nodes that the autoscaler keeps in the node group."
  type        = number
  default     = 3
}

variable "node_pool_max_count" {
  description = "Maximum number of nodes that the autoscaler can scale the node group to."
  type        = number
  default     = 6
}

variable "node_labels" {
  description = "Kubernetes node labels applied to the managed node group."
  type        = map(string)
  default = {
    "purpose" = "xmpp"
  }
}

variable "node_tags" {
  description = "EC2 instance tags propagated to worker nodes."
  type        = map(string)
  default = {
    "cluster"  = "xmpp",
    "workload" = "xmpp"
  }
}

variable "resource_tags" {
  description = "Default tags applied to AWS resources."
  type        = map(string)
  default = {
    "app"     = "xmpp",
    "env"     = "prod",
    "managed" = "terraform"
  }
}

variable "enable_ejabberd_rds" {
  description = "Set to true to provision an RDS PostgreSQL instance for ejabberd."
  type        = bool
  default     = false
}

variable "ejabberd_rds_identifier" {
  description = "Identifier for the ejabberd RDS instance."
  type        = string
  default     = "ejabberd-db"
}

variable "ejabberd_rds_db_name" {
  description = "Logical database name for ejabberd."
  type        = string
  default     = "ejabberd"
}

variable "ejabberd_rds_username" {
  description = "Database user for ejabberd."
  type        = string
  default     = "ejabberd_app"
}

variable "ejabberd_rds_instance_class" {
  description = "RDS instance class for ejabberd."
  type        = string
  default     = "db.m6i.large"
}

variable "ejabberd_rds_allocated_storage" {
  description = "Initial storage (GB) allocated to the ejabberd database."
  type        = number
  default     = 100
}

variable "ejabberd_rds_max_allocated_storage" {
  description = "Optional upper bound for storage autoscaling (GB). Set 0 to disable."
  type        = number
  default     = 0
}

variable "ejabberd_rds_backup_retention_days" {
  description = "Number of days to retain automated backups for ejabberd."
  type        = number
  default     = 7
}

variable "ejabberd_rds_multi_az" {
  description = "Enable Multi-AZ for ejabberd RDS."
  type        = bool
  default     = true
}

variable "ejabberd_rds_maintenance_window" {
  description = "Optional maintenance window for ejabberd (e.g., Sun:05:00-Sun:06:00)."
  type        = string
  default     = null
}

variable "ejabberd_rds_deletion_protection" {
  description = "Protect the ejabberd RDS instance from deletion."
  type        = bool
  default     = true
}

variable "ejabberd_rds_performance_insights_enabled" {
  description = "Enable Performance Insights for ejabberd."
  type        = bool
  default     = true
}

variable "ejabberd_rds_enable_iam_auth" {
  description = "Enable IAM database authentication for ejabberd."
  type        = bool
  default     = false
}

variable "enable_openfire_rds" {
  description = "Set to true to provision an RDS PostgreSQL instance for openfire."
  type        = bool
  default     = false
}

variable "openfire_rds_identifier" {
  description = "Identifier for the openfire RDS instance."
  type        = string
  default     = "openfire-db"
}

variable "openfire_rds_db_name" {
  description = "Logical database name for openfire."
  type        = string
  default     = "openfire"
}

variable "openfire_rds_username" {
  description = "Database user for openfire."
  type        = string
  default     = "openfire_app"
}

variable "openfire_rds_instance_class" {
  description = "RDS instance class for openfire."
  type        = string
  default     = "db.m6i.large"
}

variable "openfire_rds_allocated_storage" {
  description = "Initial storage (GB) allocated to the openfire database."
  type        = number
  default     = 100
}

variable "openfire_rds_max_allocated_storage" {
  description = "Optional upper bound for storage autoscaling (GB). Set 0 to disable."
  type        = number
  default     = 0
}

variable "openfire_rds_backup_retention_days" {
  description = "Number of days to retain automated backups for openfire."
  type        = number
  default     = 7
}

variable "openfire_rds_multi_az" {
  description = "Enable Multi-AZ for openfire RDS."
  type        = bool
  default     = true
}

variable "openfire_rds_maintenance_window" {
  description = "Optional maintenance window for openfire (e.g., Sun:05:00-Sun:06:00)."
  type        = string
  default     = null
}

variable "openfire_rds_deletion_protection" {
  description = "Protect the openfire RDS instance from deletion."
  type        = bool
  default     = true
}

variable "openfire_rds_performance_insights_enabled" {
  description = "Enable Performance Insights for openfire."
  type        = bool
  default     = true
}

variable "openfire_rds_enable_iam_auth" {
  description = "Enable IAM database authentication for openfire."
  type        = bool
  default     = true
}

variable "enable_openfire_irsa" {
  description = "Create an IAM role for the openfire Kubernetes service account (IRSA) to support IAM DB authentication."
  type        = bool
  default     = true
}

variable "openfire_service_account_namespace" {
  description = "Kubernetes namespace for the openfire IRSA binding."
  type        = string
  default     = "openfire"
}

variable "openfire_service_account_name" {
  description = "Kubernetes service account name for the openfire IRSA binding."
  type        = string
  default     = "openfire"
}
