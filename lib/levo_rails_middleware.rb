# frozen_string_literal: true

require 'levo_rails_middleware/version'
require 'levo_rails_middleware/configuration'
require 'levo_rails_middleware/middleware'
require 'levo_rails_middleware/entry'
require 'levo_rails_middleware/sender'

module LevoRailsmiddleware
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
      app_config.middleware.insert_before 'Rails::Rack::Logger', LevoRailsmiddleware::Middleware
    end
    
    # Log exceptions
    def log_exception(context, exception)
      Rails.logger.error "LEVO_middleware: Exception while #{context}: #{exception.message} (#{exception.class.name})"
      exception.backtrace&.each do |line|
        Rails.logger.error "LEVO_middleware:   #{line}"
      end
    end
  end
end