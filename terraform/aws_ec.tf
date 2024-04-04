# セキュリティグループの設定（EC）
resource "aws_security_group" "ec" {
  name        = "okamemo-ec"
  description = "okamemo ec"
  vpc_id      = aws_vpc.main.id

  # アウトバウンドルール
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "okamemo-ec"
  }
}

# セキュリティグループルール（EC）
resource "aws_security_group_rule" "ec_redis" {
  security_group_id = aws_security_group.ec.id

  depends_on = [aws_security_group_rule.ecs]

  # インバウンドルール
  type = "ingress"

  from_port = 6379
  to_port   = 6379
  protocol  = "tcp"

  source_security_group_id = aws_security_group.ecs.id
}

# ECサブネットグループ（Redis用）
resource "aws_elasticache_subnet_group" "ec" {
  name       = "okamemo-ec-subnet-group"
  subnet_ids = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]

  tags = {
    Name = "okamemo-ec-subnet-group"
  }
}

# EC Redisキャッシュ
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "okamemo-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.ec.name
  security_group_ids   = [aws_security_group.ec.id]
}
