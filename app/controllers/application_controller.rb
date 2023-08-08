class ApplicationController < ActionController::Base
  # テスト表示用のpage
  def test
    render body: "Test TOP Page"
  end
end
