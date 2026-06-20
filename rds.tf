resource "aws_db_subnet_group" "postgres" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = local.selected_subnet_ids

  tags = merge(local.tags, { Name = "${var.name_prefix}-db-subnets" })
}

resource "aws_db_instance" "postgres" {
  identifier        = "${var.name_prefix}-postgres"
  engine            = "postgres"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0
  apply_immediately       = true

  tags = merge(local.tags, { Name = "${var.name_prefix}-postgres" })
}
