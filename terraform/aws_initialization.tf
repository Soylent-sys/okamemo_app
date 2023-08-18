# プロバイダ設定
provider "aws" {
  region = "ap-northeast-1"
}

# アカウントIDの読み込み
data "aws_caller_identity" "self" { }

# AWS Secret Managerからシークレット情報を取得
data "aws_secretsmanager_secret" "main" {
  name = "okamemo/secrets"
}

data "aws_secretsmanager_secret_version" "ver_main" {
  secret_id = data.aws_secretsmanager_secret.main.id
}

# シークレット情報をローカル変数に格納する
locals {
  secrets = jsondecode(data.aws_secretsmanager_secret_version.ver_main.secret_string)
}
