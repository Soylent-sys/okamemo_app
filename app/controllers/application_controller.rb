class ApplicationController < ActionController::Base
  # see_otherなどのリダイレクトのステータスコードを付けてrenderすると
  # RSpec上ではリダイレクトできないためテスト環境のみステータスコードを
  # okにしてRSpec上でも開発・本番環境と同じ動作をするようにする
  def render_with_status_see_other(template)
    if Rails.env.test?
      render template, status: :ok
    else
      render template, status: :see_other
    end
  end
end
