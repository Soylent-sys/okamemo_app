# システムスペック用（Capybara専用）のログインヘルパー
module LoginSupport
  def sign_in_as(user)
    visit root_path
    click_link "ログイン"
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: user.password
    click_button "ログイン"
  end
end

# リクエストスペック用のログインヘルパー
module RequestLoginSupport
  def sign_in_as_request(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: user.password,
      },
    }
  end
end

RSpec.configure do |config|
  config.include LoginSupport, type: :system
  config.include RequestLoginSupport, type: :request
end
