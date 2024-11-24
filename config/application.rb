require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ChatSystem
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.api_only = true
    config.debug_exception_response_format = :api
    config.load_defaults 5.2
    config.active_job.queue_adapter = :sidekiq
    Sidekiq.configure_server do |config|
      config.on(:startup) do
        Sidekiq::Scheduler.dynamic = true
      end
    end
    config.chat_queue_threshold = ENV.fetch("CHAT_QUEUE_THRESHOLD", 10).to_i
    config.message_queue_threshold = ENV.fetch("MESSAGE_QUEUE_THRESHOLD", 10).to_i

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
