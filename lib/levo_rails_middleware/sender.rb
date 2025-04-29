# frozen_string_literal: true
require 'net/http'
require 'uri'

module LevoRailsmiddleware
  class Sender
    def initialize(remote_url)
      @remote_url = remote_url
      @uri = URI.parse(remote_url) if remote_url
    end
    
    def send_async(entry)
      return if @remote_url.nil?
      
      # Use a separate thread to avoid blocking the request
      Thread.new do
        begin
          send_data(entry)
        rescue => e
          LevoRailsmiddleware.log_exception("sending data", e)
        ensure
          # Ensure database connection is released
          ActiveRecord::Base.connection_pool.release_connection if defined?(ActiveRecord)
        end
      end
    end
    
    private
    
    def send_data(entry)
      http = Net::HTTP.new(@uri.host, @uri.port)
      
      # Configure HTTPS if needed
      if @uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      
      # Set timeouts
      timeout = LevoRailsmiddleware.configuration.timeout_seconds
      http.open_timeout = timeout
      http.read_timeout = timeout
      
      # Create request
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.content_type = 'application/json'
      request.body = entry.to_json
      
      # Add request ID header if available
      request_id = entry.request[:request_id]
      request['X-Request-ID'] = request_id if request_id
      
      # Send request
      response = http.request(request)
      
      # Log result
      if response.code.to_i >= 200 && response.code.to_i < 300
        Rails.logger.debug "LEVO_middleware: Successfully sent request data"
      else
        Rails.logger.error "LEVO_middleware: Failed to send data. Status: #{response.code}"
      end
    end
  end
end