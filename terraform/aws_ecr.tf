# ECRリポジトリ（アプリコンテナ用）
resource "aws_ecr_repository" "app" {
  name = "okamemo_app_rails"
  force_delete = true # terraform destroyしたときにリポジトリに画像が存在しても削除される
}

# ECRリポジトリ（webサーバーコンテナ用）
resource "aws_ecr_repository" "web" {
  name = "okamemo_web_nginx"
  force_delete = true
}

# ECRリポジトリ（sidekiqコンテナ用）
resource "aws_ecr_repository" "worker" {
  name = "okamemo_worker_sidekiq"
  force_delete = true
}
