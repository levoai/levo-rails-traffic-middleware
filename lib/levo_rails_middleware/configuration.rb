# frozen_string_literal: true

module LevoRailsmiddleware
    class Configuration
      attr_accessor :remote_url, :sampling_rate, :exclude_paths, :filter_params
      attr_accessor :size_threshold_kb, :timeout_seconds, :enabled
      
      def initialize
        @remote_url = ENV['LEVO_middleware_URL']
        @sampling_rate = 1.0  # 100% by default
        @exclude_paths = ['/assets/', '/packs/', '/health']
        @filter_params = ['password', 'token', 'api_key', 'secret']
        @size_threshold_kb = 1024  # Skip bodies larger than 1MB
        @timeout_seconds = 3
        @enabled = true
      end
    end
  end