# 管理ユーザーがアクセス可能なページのルーティングで使用
# リクエストに関連するユーザーがサインイン状態且つ管理ユーザーであるかを判定
class AdminConstraint
  def self.matches?(request)
    user = request.env["warden"].user(:user)  # Devise の現在のユーザーを取得する
    user.present? && user.admin?
  end
end
