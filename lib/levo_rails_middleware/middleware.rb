# frozen_string_literal: true

module LevoRailsmiddleware
    class Middleware
      def initialize(app)
        @app = app
        @sender = Sender.new(LevoRailsmiddleware.configuration.remote_url)
      rescue => e
        LevoRailsmiddleware.log_exception("initializing middleware", e)
        @initialization_failed = true
      end
  
      def call(env)
        # Skip processing if initialization failed or middleware is disabled
        return @app.call(env) if @initialization_failed || !LevoRailsmiddleware.configuration.enabled
        
        # Skip excluded paths
        path = env['PATH_INFO'] || ""
        return @app.call(env) if should_skip?(path)
        
        # Skip based on sampling rate
        return @app.call(env) if rand > LevoRailsmiddleware.configuration.sampling_rate
        
        start_time = Time.now
        
        # Preserve the original request body
        request_body = env['rack.input'].read
        env['rack.input'].rewind
        
        # Process the request through the app
        status, headers, body = @app.call(env)
        end_time = Time.now
        
        # Calculate the request duration
        duration_ms = ((end_time.to_f - start_time.to_f) * 1000).round
        
        # Save the original input stream
        saved_input = env['rack.input']
        env['rack.input'] = StringIO.new(request_body)
        
        # Create the request/response entry and send it
        begin
          entry = Entry.new(start_time, duration_ms, env, status, headers, body)
          @sender.send_async(entry)
        rescue => e
          LevoRailsmiddleware.log_exception("processing request", e)
        ensure
          # Restore the original input stream
          env['rack.input'] = saved_input
        end
        
        [status, headers, body]
      rescue => e
        LevoRailsmiddleware.log_exception("middleware execution", e)
        @app.call(env)  # Ensure we still call the app even if our middleware fails
      end
      
      private
      
      def should_skip?(path)
        LevoRailsmiddleware.configuration.exclude_paths.any? do |excluded|
          path.start_with?(excluded)
        end
      end
    end
  end