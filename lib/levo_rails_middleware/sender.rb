# frozen_string_literal: true
require 'net/http'
require 'uri'
require 'json'
require 'securerandom'

module LevoRailsmiddleware
  class Sender
    API_ENDPOINT = "/1.0/ebpf/traces"

    def initialize(remote_url)
      @remote_url = remote_url
      @uri = URI.parse(remote_url) if remote_url
      Rails.logger.info "LEVO_MIRROR: Initialized with URL #{@remote_url}" if defined?(Rails)
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
      # Convert entry to Levo Satellite format
      trace = convert_to_satellite_format(entry)
      json_data = JSON.generate([trace])

      Rails.logger.debug "LEVO_MIRROR: JSON payload preview (first 200 chars): #{json_data[0..200]}..." if defined?(Rails)

      # Create HTTP client
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

      # Construct API path correctly
      endpoint_path = API_ENDPOINT
      base_path = @uri.path.to_s

      # Ensure the path is properly formed
      if base_path.empty?
        full_path = endpoint_path
      else
        # Handle trailing slashes correctly
        if base_path.end_with?('/') && endpoint_path.start_with?('/')
          full_path = base_path + endpoint_path[1..-1]
        elsif !base_path.end_with?('/') && !endpoint_path.start_with?('/')
          full_path = "#{base_path}/#{endpoint_path}"
        else
          full_path = base_path + endpoint_path
        end
      end

      # Create request with the properly formed path
      request = Net::HTTP::Post.new(full_path)
      request.content_type = 'application/json'

      # Add Levo organization ID header
      if LevoRailsmiddleware.configuration.organization_id
        request['x-levo-organization-id'] = LevoRailsmiddleware.configuration.organization_id
      end

      # Add request ID header if available
      request_id = entry.request[:request_id]
      request['X-Request-ID'] = request_id if request_id

      # Set the request body
      request.body = json_data

      # Send request with retry logic
      response = nil
      success = false

      # Retry logic
      max_retries = LevoRailsmiddleware.configuration.max_retries

      for attempt in 0...max_retries
        if attempt > 0
          # Exponential backoff with jitter
          backoff_ms = (2 ** attempt) * 100 + rand(1000)
          sleep(backoff_ms / 1000.0)
          Rails.logger.info "LEVO_MIRROR: Retry attempt #{attempt+1} for sending trace data" if defined?(Rails)
        end

        begin
          response = http.request(request)

          # Check status code
          if response.code.to_i >= 200 && response.code.to_i < 300
            success = true
            break
          else
            Rails.logger.error "LEVO_MIRROR: Failed to send data. Status: #{response.code}" if defined?(Rails)
          end
        rescue => e
          Rails.logger.error "LEVO_MIRROR: Error during HTTP request: #{e.message}" if defined?(Rails)
        end
      end

      if success
        Rails.logger.info "LEVO_MIRROR: Successfully sent trace data, status: #{response.code}" if defined?(Rails)
      else
        Rails.logger.error "LEVO_MIRROR: Failed to send trace after #{max_retries} attempts" if defined?(Rails)
      end
    end

    def convert_to_satellite_format(entry)
      # Generate trace and span IDs similar to the C++ implementation
      trace_id = SecureRandom.uuid
      span_id = SecureRandom.uuid

      # Calculate duration in nanoseconds
      duration_ns = entry.duration_ms * 1_000_000

      # Get current time in nanoseconds
      request_time_ns = (Time.now.to_f * 1_000_000_000).to_i

      # Extract request method and path
      method = entry.request[:method]
      path = entry.request[:path]

      # Convert headers to the expected format
      request_headers = {}
      entry.request[:headers].each do |name, value|
        request_headers[name.downcase] = value
      end

      # Add special headers that the backend expects
      request_headers[":path"] = path
      request_headers[":method"] = method
      request_headers[":authority"] = request_headers["host"] if request_headers["host"]

      response_headers = {}
      entry.response[:headers].each do |name, value|
        response_headers[name.downcase] = value
      end

      # Add special response headers
      response_headers[":status"] = entry.response[:status].to_s

      # Build the trace structure
      {
        "http_scheme" => (request_headers['x-forwarded-proto'] || 'http'),
        "request" => {
          "headers" => request_headers,
          "body" => Base64.strict_encode64(entry.request[:body].to_s),
          "truncated" => false
        },
        "response" => {
          "headers" => response_headers,
          "body" => Base64.strict_encode64(entry.response[:body].to_s),
          "truncated" => false,
          "status_code" => entry.response[:status]
        },
        "resource" => {
          "service_name" => LevoRailsmiddleware.configuration.service_name,
          "host_name" => LevoRailsmiddleware.configuration.host_name,
          "telemetry_sdk_language" => "ruby",
          "telemetry_sdk_name" => "levo_rails_middleware",
          "telemetry_sdk_version" => LevoRailsmiddleware::VERSION,
          "levo_env" => LevoRailsmiddleware.configuration.environment_name
        },
        "duration_ns" => duration_ns,
        "request_time_ns" => request_time_ns,
        "trace_id" => trace_id,
        "span_id" => span_id,
        "span_kind" => "SERVER",
        "path" => path,
        "method" => method,
        "client_ip" => entry.request[:remote_ip]
      }
    end
  end
end