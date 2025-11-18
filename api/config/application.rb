require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)

module DiggApi
  class Application < Rails::Application
    config.load_defaults 6.1
    config.api_only = true

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end

    config.autoload_paths << Rails.root.join('lib')

    config.time_zone = 'UTC'
    config.active_record.default_timezone = :utc
  end
end
