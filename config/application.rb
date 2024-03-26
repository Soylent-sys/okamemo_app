require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OkamemoApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.time_zone = "Asia/Tokyo"
    config.active_record.default_timezone = :local

    config.i18n.default_locale = :ja
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]

    config.generators do |g|
      g.test_framework :rspec,
        fixtures: false,
        helper_specs: false,
        view_specs: false,
        routing_specs: false
    end

    config.action_view.field_error_proc = Proc.new { |html_tag, instance| html_tag.html_safe }

    # メール送信処理のジョブを永続化するためジョブキューアダプターをsidekiqに設定
    config.active_job.queue_adapter = :sidekiq
  end
end
