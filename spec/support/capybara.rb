require 'capybara/rspec'
require 'selenium-webdriver'

Capybara.register_driver :remote_chrome do |app|
  url = ENV["SELENIUM_DRIVER_URL"]
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("no-sandbox")
  options.add_argument("headless")
  options.add_argument("disable-gpu")
  options.add_argument("window-size=1680,1050")
  options.add_argument("disable-dev-shm-usage")

  Capybara::Selenium::Driver.new(app,
                                 browser: :remote,
                                 url: url,
                                 capabilities: options)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    Capybara.server_host = IPSocket.getaddress(Socket.gethostname)
    Capybara.server_port = 4444
    Capybara.app_host = "http://#{Capybara.server_host}:#{Capybara.server_port}"
    driven_by :remote_chrome
  end
end

# selenium使用時(js: trueオプション使用時)のテスト失敗時のスクリーンショット保存場所
Capybara.save_path = Rails.root.join("spec/tmp/screenshots")
