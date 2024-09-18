module LoginSupport
  def sign_in_as(user)
    visit root_path
    click_link "ログイン"
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: user.password
    click_button "ログイン"
  end
end

RSpec.configure do |config|
  config.include LoginSupport
end
