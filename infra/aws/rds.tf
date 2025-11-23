locals {
  db_allowed_cidrs      = [var.vpc_cidr]
  openfire_irsa_enabled = var.enable_openfire_rds && var.enable_openfire_irsa
}

module "ejabberd_rds" {
  count = var.enable_ejabberd_rds ? 1 : 0

  source = "./modules/rds_postgres"

  identifier                   = var.ejabberd_rds_identifier
  db_name                      = var.ejabberd_rds_db_name
  username                     = var.ejabberd_rds_username
  instance_class               = var.ejabberd_rds_instance_class
  allocated_storage            = var.ejabberd_rds_allocated_storage
  max_allocated_storage        = var.ejabberd_rds_max_allocated_storage
  backup_retention_days        = var.ejabberd_rds_backup_retention_days
  multi_az                     = var.ejabberd_rds_multi_az
  maintenance_window           = var.ejabberd_rds_maintenance_window
  deletion_protection          = var.ejabberd_rds_deletion_protection
  performance_insights_enabled = var.ejabberd_rds_performance_insights_enabled
  enable_iam_auth              = var.ejabberd_rds_enable_iam_auth
  subnet_ids                   = values(aws_subnet.private)[*].id
  vpc_id                       = aws_vpc.main.id
  allowed_cidr_blocks          = local.db_allowed_cidrs
  tags = merge(var.resource_tags, {
    app = "ejabberd"
  })
}

module "openfire_rds" {
  count = var.enable_openfire_rds ? 1 : 0

  source = "./modules/rds_postgres"

  identifier                   = var.openfire_rds_identifier
  db_name                      = var.openfire_rds_db_name
  username                     = var.openfire_rds_username
  instance_class               = var.openfire_rds_instance_class
  allocated_storage            = var.openfire_rds_allocated_storage
  max_allocated_storage        = var.openfire_rds_max_allocated_storage
  backup_retention_days        = var.openfire_rds_backup_retention_days
  multi_az                     = var.openfire_rds_multi_az
  maintenance_window           = var.openfire_rds_maintenance_window
  deletion_protection          = var.openfire_rds_deletion_protection
  performance_insights_enabled = var.openfire_rds_performance_insights_enabled
  enable_iam_auth              = var.openfire_rds_enable_iam_auth
  subnet_ids                   = values(aws_subnet.private)[*].id
  vpc_id                       = aws_vpc.main.id
  allowed_cidr_blocks          = local.db_allowed_cidrs
  tags = merge(var.resource_tags, {
    app = "openfire"
  })
}

data "aws_iam_policy_document" "openfire_irsa_assume" {
  count = local.openfire_irsa_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.openfire_service_account_namespace}:${var.openfire_service_account_name}"]
    }
  }
}

resource "aws_iam_role" "openfire_irsa" {
  count = local.openfire_irsa_enabled ? 1 : 0

  name               = "${var.cluster_name}-openfire"
  assume_role_policy = data.aws_iam_policy_document.openfire_irsa_assume[0].json

  tags = merge(var.resource_tags, {
    Name = "${var.cluster_name}-openfire"
  })
}

data "aws_iam_policy_document" "openfire_db_access" {
  count = local.openfire_irsa_enabled && var.openfire_rds_enable_iam_auth ? 1 : 0

  statement {
    actions = ["rds-db:connect"]
    effect  = "Allow"
    resources = [
      "arn:${data.aws_partition.current.partition}:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.openfire_rds[0].db_resource_id}/${var.openfire_rds_username}"
    ]
  }
}

resource "aws_iam_policy" "openfire_db_access" {
  count = local.openfire_irsa_enabled && var.openfire_rds_enable_iam_auth ? 1 : 0

  name        = "${var.cluster_name}-openfire-db"
  description = "Allow openfire service account to connect to RDS using IAM auth"
  policy      = data.aws_iam_policy_document.openfire_db_access[0].json

  tags = merge(var.resource_tags, {
    Name = "${var.cluster_name}-openfire-db"
  })
}

resource "aws_iam_role_policy_attachment" "openfire_db_access" {
  count = local.openfire_irsa_enabled && var.openfire_rds_enable_iam_auth ? 1 : 0

  role       = aws_iam_role.openfire_irsa[0].name
  policy_arn = aws_iam_policy.openfire_db_access[0].arn
}
