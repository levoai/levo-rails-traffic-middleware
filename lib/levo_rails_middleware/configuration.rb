# frozen_string_literal: true

module LevoRailsmiddleware
  class Configuration
    attr_accessor :remote_url, :sampling_rate, :exclude_paths, :filter_params
    attr_accessor :size_threshold_kb, :timeout_seconds, :enabled
    attr_accessor :organization_id, :environment_name, :service_name, :host_name
    attr_accessor :max_retries
    
    def initialize
      @remote_url = ENV['LEVO_SATELLITE_URL'] || 'https://collector.levo.ai'
      @sampling_rate = 1.0  # 100% by default
      @exclude_paths = ['/assets/', '/packs/', '/health']
      @filter_params = ['password', 'token', 'api_key', 'secret']
      @size_threshold_kb = 1024  # Skip bodies larger than 1MB
      @timeout_seconds = 3
      @enabled = true
      
      # Levo Satellite specific configuration
      @organization_id = ENV['LEVOAI_ORG_ID']
      @environment_name = ENV['LEVO_ENV']
      @service_name = ENV['LEVO_SERVICE_NAME'] || 'rails-application'
      @host_name = get_hostname
      @max_retries = 3
    end
    
    private
    
    def get_hostname
      # Try to get the hostname, fallback to 'unknown-host'
      begin
        Socket.gethostname
      rescue
        'unknown-host'
      end
    end
  end
end