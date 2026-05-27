# セキュリティグループの設定（ECS）
resource "aws_security_group" "ecs" {
  name        = "okamemo-ecs"
  description = "okamemo ecs"

  # セキュリティグループを配置するVPC
  vpc_id = aws_vpc.main.id

  # セキュリティグループ内のリソースからインターネットへのアクセス許可設定
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "okamemo-ecs"
  }
}

# セキュリティグループルールの設定（ECS）
resource "aws_security_group_rule" "ecs" {
  security_group_id = aws_security_group.ecs.id
  # インターネットからセキュリティグループ内のリソースへのアクセス許可設定
  type = "ingress"

  # TCPでの80ポートへのアクセスを許可する
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}


# webサーバを立ち上げるための設定
# タスク定義の作成
resource "aws_ecs_task_definition" "main" {
  family = "okamemo-app-task"

  # データプレーン
  requires_compatibilities = ["FARGATE"]

  # ECSタスクが使用可能なリソースの上限
  # タスク内のコンテナはこの上限内に使用するリソースを収める必要があり、メモリが上限に達した場合OOM Killer にタスクがキルされる
  cpu    = "256"
  memory = "1024"

  # ECSタスクのネットワークドライバ
  # Fargateを使用する場合は"awsvpc"決め打ち
  network_mode = "awsvpc"

  # タスク実行ロールをecsTaskExecutionRoleとする
  execution_role_arn = "arn:aws:iam::${data.aws_caller_identity.self.account_id}:role/ecsTaskExecutionRole"

  # 起動するコンテナの定義
  # rails、nginxコンテナを起動
  # railsコンテナ: 3000番ポートを開放、環境変数を設定
  # nginxコンテナの80番ポートを開放、railsコンテナのボリュームを共有
  # sidekiqコンテナ: railsコンテナと同様の環境変数を設定、railsコンテナ起動後に起動する設定
  container_definitions = <<SET
[
  {
    "name": "rails",
    "image": "${aws_ecr_repository.app.repository_url}",
    "cpu": 0,
    "portMappings": [
        {
            "containerPort": 3000,
            "hostPort": 3000,
            "protocol": "tcp"
        }
    ],
    "essential": true,
    "entryPoint": [],
    "command": [],
    "environment": [
        {
          "name": "MYSQL_HOST",
          "value": "${aws_db_instance.db.address}"
        },
        {
          "name": "REDIS_URL",
          "value": "redis://${aws_elasticache_cluster.redis.cache_nodes.0.address}:6379"
        }
    ],
    "secrets": [
        {
          "name": "AWS_ACCESS_KEY_ID",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:AWS_ACCESS_KEY_ID::"
        },
        {
          "name": "AWS_SECRET_ACCESS_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:AWS_SECRET_ACCESS_KEY::"
        },
        {
          "name": "MYSQL_USERNAME",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:MYSQL_USERNAME::"
        },
        {
          "name": "MYSQL_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:MYSQL_PASSWORD::"
        },
        {
          "name": "RAILS_MASTER_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:RAILS_MASTER_KEY::"
        },
        {
          "name": "SES_AWS_ACCESS_KEY_ID",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:SES_AWS_ACCESS_KEY_ID::"
        },
        {
          "name": "SES_AWS_SECRET_ACCESS_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:SES_AWS_SECRET_ACCESS_KEY::"
        },
        {
          "name": "HASHID_SALT_CHAR",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:HASHID_SALT_CHAR::"
        },
        {
          "name": "GOOGLE_MAP_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:GOOGLE_MAP_API_KEY::"
        },
        {
          "name": "ADMIN_USER_EMAIL",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:ADMIN_USER_EMAIL::"
        },
        {
          "name": "ADMIN_USER_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:ADMIN_USER_PASSWORD::"
        },
        {
          "name": "CONTACT_EMAIL",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:CONTACT_EMAIL::"
        },
        {
          "name": "RECAPTCHA_SITE_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:RECAPTCHA_SITE_KEY::"
        },
        {
          "name": "RECAPTCHA_SECRET_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:RECAPTCHA_SECRET_KEY::"
        }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "/ecs/okamemo-app-task",
            "awslogs-region": "ap-northeast-1",
            "awslogs-stream-prefix": "ecs"
        }
    },
    "mountPoints": [],
    "volumesFrom": []
  },
  {
    "name": "nginx",
    "image": "${aws_ecr_repository.web.repository_url}",
    "cpu": 0,
    "portMappings": [
        {
            "containerPort": 80,
            "hostPort": 80,
            "protocol": "tcp"
        }
    ],
    "essential": true,
    "entryPoint": [],
    "command": [],
    "environment": [],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "/ecs/okamemo-app-task",
            "awslogs-region": "ap-northeast-1",
            "awslogs-stream-prefix": "ecs"
        }
    },
    "mountPoints": [],
    "volumesFrom": [
        {
            "sourceContainer": "rails"
        }
    ]
  },
  {
    "name": "sidekiq",
    "image": "${aws_ecr_repository.worker.repository_url}",
    "cpu": 0,
    "essential": true,
    "entryPoint": [],
    "command": [],
    "environment": [
        {
          "name": "MYSQL_HOST",
          "value": "${aws_db_instance.db.address}"
        },
        {
          "name": "REDIS_URL",
          "value": "redis://${aws_elasticache_cluster.redis.cache_nodes.0.address}:6379"
        }
    ],
    "secrets": [
        {
          "name": "AWS_ACCESS_KEY_ID",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:AWS_ACCESS_KEY_ID::"
        },
        {
          "name": "AWS_SECRET_ACCESS_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:AWS_SECRET_ACCESS_KEY::"
        },
        {
          "name": "MYSQL_USERNAME",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:MYSQL_USERNAME::"
        },
        {
          "name": "MYSQL_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:MYSQL_PASSWORD::"
        },
        {
          "name": "RAILS_MASTER_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:RAILS_MASTER_KEY::"
        },
        {
          "name": "SES_AWS_ACCESS_KEY_ID",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:SES_AWS_ACCESS_KEY_ID::"
        },
        {
          "name": "SES_AWS_SECRET_ACCESS_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:SES_AWS_SECRET_ACCESS_KEY::"
        },
        {
          "name": "HASHID_SALT_CHAR",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:HASHID_SALT_CHAR::"
        },
        {
          "name": "GOOGLE_MAP_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:GOOGLE_MAP_API_KEY::"
        },
        {
          "name": "ADMIN_USER_EMAIL",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:ADMIN_USER_EMAIL::"
        },
        {
          "name": "ADMIN_USER_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:ADMIN_USER_PASSWORD::"
        },
        {
          "name": "CONTACT_EMAIL",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:CONTACT_EMAIL::"
        },
        {
          "name": "RECAPTCHA_SITE_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:RECAPTCHA_SITE_KEY::"
        },
        {
          "name": "RECAPTCHA_SECRET_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:${data.aws_caller_identity.self.account_id}:secret:okamemo/secrets-CIFgQn:RECAPTCHA_SECRET_KEY::"
        }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "/ecs/okamemo-app-task",
            "awslogs-region": "ap-northeast-1",
            "awslogs-stream-prefix": "ecs"
        }
    },
    "mountPoints": [],
    "volumesFrom": [],
    "dependsOn": [
      {
        "containerName": "rails",
        "condition": "START"
      }
    ]
  }
]
SET
}

# ECSクラスターの作成
resource "aws_ecs_cluster" "main" {
  name = "okamemo-app-cluster"
}

# ECSサービス
resource "aws_ecs_service" "main" {
  name = "okamemo-app-service"

  # 依存関係の記述
  # "aws_lb_listener_rule.main" リソースの作成が完了するのを待ってから当該リソースの作成を開始する
  # "depends_on" は "aws_ecs_service" リソース専用のプロパティではなく、Terraformのシンタックスのため他の"resource"でも使用可能
  depends_on = [aws_lb_listener_rule.main]

  # 当該ECSサービスを配置するECSクラスターの指定
  cluster = aws_ecs_cluster.main.id

  # データプレーンとしてFargateを使用する
  launch_type = "FARGATE"

  # ECSタスクの起動数を定義(アプリリリース時は"2"に設定する)
  desired_count = "1"

  # 起動するECSタスクのタスク定義
  task_definition = aws_ecs_task_definition.main.arn

  # ECSタスクへ設定するネットワークの設定
  network_configuration {
    # タスクの起動を許可するサブネット
    subnets         = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]
    # タスクに紐付けるセキュリティグループ
    security_groups = [aws_security_group.ecs.id]
    # パブリックIPの割当て
    assign_public_ip = true
  }

  # ECSタスクの起動後に紐付けるELBターゲットグループ
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name = "nginx"
    container_port = "80"
  }
}
