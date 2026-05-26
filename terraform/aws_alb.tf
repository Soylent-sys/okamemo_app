# セキュリティグループ（ALB）
resource "aws_security_group" "alb" {
  name        = "okamemo-alb"
  description = "okamemo-alb"
  vpc_id      = aws_vpc.main.id

  # アウトバウンドルール
  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = {
    Name = "okamemo-alb"
  }
}

# セキュリティグループルール（ALB）
resource "aws_security_group_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  # インバウンドルール
  type = "ingress"

  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}


# ロードバランサーとコンテナの紐付け
# ALB（ロードバランサー設定）
resource "aws_lb" "main" {
  load_balancer_type = "application"
  name               = "okamemo-alb"

  security_groups = [aws_security_group.alb.id]
  subnets = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]
}

# ALBリスナー設定
resource "aws_lb_listener" "main" {
  # httpでのアクセスを受け付ける
  port     = "80"
  protocol = "HTTP"

  # ALBのARNを指定
  load_balancer_arn = aws_lb.main.arn

  # "ok"の固定レスポンスを設定（ALB疎通確認用としてデフォルトアクションに設定）
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "ok"
    }
  }
}

# ELBターゲット設定
resource "aws_lb_target_group" "main" {
  name = "okamemo"

  # ターゲットグループを作成するVPC
  vpc_id = aws_vpc.main.id

  # ALBからECSタスクのコンテナへトラフィックを振り分ける設定
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  # コンテナへの死活監視の設定
  health_check {
    port = 80
    path = "/"
    matcher = "200,301"
  }
}

# ALBリスナールール設定
resource "aws_lb_listener_rule" "main" {
  # ルールを追加するリスナー
  listener_arn = aws_lb_listener.main.arn

  # 受け取ったトラフィックをターゲットグループへ転送する
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  # ターゲットグループに受け渡すトラフィックの条件
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
