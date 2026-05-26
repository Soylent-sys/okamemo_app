# セキュリティグループ（RDS）
resource "aws_security_group" "rds" {
  name        = "okamemo-rds"
  description = "okamemo-rds"
  vpc_id      = aws_vpc.main.id

  # アウトバウンドルール
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "okamemo-rds"
  }
}

# セキュリティグループルール（RDS）
resource "aws_security_group_rule" "rds_mysql" {
  security_group_id = aws_security_group.rds.id

  # インバウンドルール
  type = "ingress"

  from_port = 3306
  to_port   = 3306
  protocol  = "tcp"

  source_security_group_id = aws_security_group.ecs.id
}

# DBサブネットグループ（RDS用）
resource "aws_db_subnet_group" "rds" {
  name       = "okamemo_rds_subnet_group"
  subnet_ids = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]

  tags = {
    Name = "okamemo_rds_subnet_group"
  }
}


# RDS DBインスタンス
resource "aws_db_instance" "db" {
  allocated_storage                   = 20
  engine                              = "mysql"
  engine_version                      = "8.0.46"
  auto_minor_version_upgrade          = true
  instance_class                      = "db.t3.micro"
  identifier                          = "okamemo-app-production"
  username                            = "${local.secrets.MYSQL_USERNAME}"
  password                            = "${local.secrets.MYSQL_PASSWORD}"
  parameter_group_name                = "default.mysql8.0"
  skip_final_snapshot                 = true
  customer_owned_ip_enabled           = false
  deletion_protection                 = false
  enabled_cloudwatch_logs_exports     = []
  iam_database_authentication_enabled = false
  max_allocated_storage               = 1000
  storage_encrypted                   = true
  tags                                = {}
  vpc_security_group_ids              = [aws_security_group.rds.id]
  db_subnet_group_name                = aws_db_subnet_group.rds.name
  copy_tags_to_snapshot               = true
}
