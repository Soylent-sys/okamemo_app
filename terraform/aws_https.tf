# https化
# 変数定義（使用ドメイン）
variable "domain" {
  description = "Route53 で管理しているドメイン名"
  type = string

  default = "okamemo.com"
}

# 手動（terraform外）で作成したRoute53ホストゾーンをterraform内で参照可能にする
data "aws_route53_zone" "main" {
  name         = var.domain
  private_zone = false
}

# ACMパブリック証明書をリクエスト（検証方法にDNSを使用する）
resource "aws_acm_certificate" "main" {
  domain_name = var.domain

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Route53ホストゾーンにレコードを作成（ACMのドメイン検証用のCNAMEレコードの作成）
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.id
}

# ACM証明書とCNAMEレコードの連携
resource "aws_acm_certificate_validation" "name" {
  certificate_arn = aws_acm_certificate.main.arn

  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

# Route53ホストゾーンにレコードを作成（ドメイン名とALBを対応付けするAレコードの作成）
resource "aws_route53_record" "main" {
  type = "A"

  name    = var.domain
  zone_id = data.aws_route53_zone.main.id

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}


# ALBリスナー設定（https通信のリスナー設定）
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn

  certificate_arn = aws_acm_certificate.main.arn

  port     = "443"
  protocol = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ALBリスナールール設定（httpでのリクエストをhttpsにリダイレクトする）
resource "aws_lb_listener_rule" "http_to_https" {
  listener_arn = aws_lb_listener.main.arn

  priority = 99

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = [var.domain]
    }
  }
}

# セキュリティグループルール設定
resource "aws_security_group_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  type = "ingress"

  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}
