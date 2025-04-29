# frozen_string_literal: true

require 'levo_rails_mirror/version'
require 'levo_rails_mirror/configuration'
require 'levo_rails_mirror/middleware'
require 'levo_rails_mirror/entry'
require 'levo_rails_mirror/sender'

module LevoRailsMirror
  class << self
    attr_writer :configuration
    
    # Access the configuration
    def configuration
      @configuration ||= Configuration.new
    end
    
    # Configure the middleware
    def configure
      yield(configuration) if block_given?
    end
    
    # Add middleware to Rails application
    def instrument(app_config)
      app_config.middleware.insert_before 'Rails::Rack::Logger', LevoRailsMirror::Middleware
    end
    
    # Log exceptions
    def log_exception(context, exception)
      Rails.logger.error "LEVO_MIRROR: Exception while #{context}: #{exception.message} (#{exception.class.name})"
      exception.backtrace&.each do |line|
        Rails.logger.error "LEVO_MIRROR:   #{line}"
      end
    end
  end
end