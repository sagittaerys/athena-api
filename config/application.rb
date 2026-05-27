require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module AthenaApi
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[ assets tasks ])
    config.api_only = true
    config.middleware.use Rack::Attack
    config.active_job.queue_adapter = :solid_queue
  end
end
