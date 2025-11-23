resource "random_password" "db" {
  length           = var.password_length
  min_special      = 4
  override_special = "@_-+."
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.identifier}-subnets"
  })
}

resource "aws_security_group" "this" {
  name        = "${var.identifier}-sg"
  description = "RDS security group for ${var.identifier}"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.identifier}-sg"
  })
}

resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.username
  password = random_password.db.result
  port     = 5432

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > var.allocated_storage ? var.max_allocated_storage : null
  storage_type          = "gp3"
  storage_encrypted     = true

  multi_az                         = var.multi_az
  backup_retention_period          = var.backup_retention_days
  maintenance_window               = var.maintenance_window
  deletion_protection              = var.deletion_protection
  performance_insights_enabled     = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null
  iam_database_authentication_enabled    = var.enable_iam_auth
  enabled_cloudwatch_logs_exports        = ["postgresql"]

  vpc_security_group_ids = [aws_security_group.this.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name
  publicly_accessible    = false
  apply_immediately      = false

  copy_tags_to_snapshot = true
  skip_final_snapshot   = !var.deletion_protection

  tags = merge(var.tags, {
    Name = var.identifier
  })
}
