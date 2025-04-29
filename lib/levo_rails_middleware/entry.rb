# frozen_string_literal: true
require 'json'

module LevoRailsmiddleware
  class Entry
    attr_reader :timestamp, :duration_ms, :request, :response
    
    def initialize(start_time, duration_ms, env, status, headers, body)
      @timestamp = start_time
      @duration_ms = duration_ms
      
      # Create Rack request object
      rack_request = Rack::Request.new(env)
      
      # Extract request data
      @request = {
        method: rack_request.request_method,
        path: rack_request.path,
        query_string: rack_request.query_string,
        headers: extract_headers(env),
        body: extract_body(rack_request.body),
        remote_ip: rack_request.ip,
        request_id: env['HTTP_X_REQUEST_ID'] || env['action_dispatch.request_id']
      }
      
      # Extract response data
      response_body = extract_response_body(body)
      
      @response = {
        status: status,
        headers: headers_to_hash(headers),
        body: response_body,
        size: response_body.bytesize
      }
    end
    
    def to_json
      {
        timestamp: @timestamp.iso8601,
        duration_ms: @duration_ms,
        request: @request,
        response: @response,
        environment: Rails.env
      }.to_json
    end
    
    private
    
    def extract_headers(env)
      headers = {}
      env.each do |key, value|
        if key.start_with?('HTTP_')
          header_name = key[5..-1].gsub('_', '-').downcase
          headers[header_name] = value
        end
      end
      headers
    end
    
    def extract_body(body)
      return "" unless body
      
      body.rewind
      content = body.read
      body.rewind
      
      # Check size threshold
      if content.bytesize > LevoRailsmiddleware.configuration.size_threshold_kb * 1024
        return "[CONTENT TOO LARGE]"
      end
      
      # Filter sensitive parameters
      filter_sensitive_data(content)
    end

    def extract_response_body(body)
      content = ""
      body.each { |part| content << part.to_s.dup }  # Use .dup to create a mutable copy

      # Check size threshold
      if content.bytesize > LevoRailsmiddleware.configuration.size_threshold_kb * 1024
        return "[CONTENT TOO LARGE]"
      end

      # Filter sensitive parameters
      filter_sensitive_data(content)
    end
    
    def headers_to_hash(headers)
      hash = {}
      headers.each do |key, value|
        hash[key.to_s] = value
      end
      hash
    end

    def filter_sensitive_data(content)
      filtered = content.to_s.dup
      LevoRailsmiddleware.configuration.filter_params.each do |param|
        # Simple regex to find and replace sensitive data
        filtered.gsub!(/["']?#{param}["']?\s*[=:]\s*["']?[^"' &,\}]+["']?/, "#{param}=[FILTERED]")
      end
      filtered
    end
  end
end