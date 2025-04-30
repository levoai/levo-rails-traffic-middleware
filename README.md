
# Levo Rails Traffic Middleware

[![Gem Version](https://badge.fury.io/rb/levo-rails-traffic-middleware.svg)](https://badge.fury.io/rb/levo-rails-traffic-middleware)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A lightweight, high-performance middleware for mirroring your Rails application API traffic to the Levo.ai platform for API security analysis.

## Overview

The Levo Rails Traffic Middleware captures HTTP requests and responses from your Rails application and securely sends them to the Levo.ai platform. This enables Levo.ai to provide API security analysis, identify vulnerabilities, and help protect your applications without requiring code changes or impacting performance.

Key features:
- **Zero-impact traffic mirroring**: Asynchronously sends data without affecting your application's response time
- **Configurable sampling rate**: Control how much traffic is mirrored
- **Sensitive data filtering**: Automatically filter confidential information
- **Path exclusion**: Skip static assets and health check endpoints
- **Size limits**: Prevent excessive data transmission for large payloads
- **Production-ready**: Built for high-throughput environments

## Requirements

- Ruby 2.6 or later
- Rails 5.0 or later

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'levo_rails_middleware', git: 'https://github.com/levoai/levo-rails-traffic-middleware.git'
```

Then execute:

```bash
$ bundle update
```

## Quick Start

After installing the gem, you need to:

1. Configure the middleware
2. Add it to your Rails application

### Configuration

Create an initializer file at `config/initializers/levo_middleware.rb`:

```ruby
require 'levo_rails_middleware'

LevoRailsMiddleware.configure do |config|
    # Required: URL for the Levo.ai traffic collector
    config.remote_url = ENV['LEVO_MIDDLEWARE_URL']
      
    # Optional configuration with defaults shown
    config.sampling_rate = 1.0       # 100% of traffic
    config.exclude_paths = ['/assets/', '/packs/', '/health']
    config.filter_params = ['password', 'token', 'api_key', 'secret']
    config.size_threshold_kb = 1024  # Skip bodies larger than 1MB     config.timeout_seconds = 3
    config.enabled = true
  end
  
  # Add the middleware to the Rails stack
  LevoRailsmiddleware.instrument(Rails.application.config)
```

### Adding the Middleware

In your `config/application.rb` file, add:

```ruby
module YourApp
  class Application < Rails::Application
    # ... other configurations ...
    
    # Add the Levo.ai traffic mirroring middleware
    require 'levo_rails_middleware'
    LevoRailsmiddleware.instrument(config)
  end
end
```

## Heroku Deployment

For Heroku applications, you'll need to set the environment variable for the Levo middleware URL:

```bash
heroku config:set LEVO_MIDDLEWARE_URL='https://collector.levo.ai (Replace with your own Satellite url'
heroku config:set LEVOAI_ORG_ID='your-org-id'
heroku config:set LEVO_ENV='your-environment-name, like Production or Staging'

```

## Configuration Options

| Option | Description | Default |
| ------ | ----------- | ------- |
| `remote_url` | The URL to send mirrored traffic to | `ENV['LEVO_MIDDLEWARE_URL']` |
| `sampling_rate` | Percentage of requests to mirror (0.0 to 1.0) | `1.0` (100%) |
| `exclude_paths` | Array of path prefixes to exclude from mirroring | `['/assets/', '/packs/', '/health']` |
| `filter_params` | Array of parameter names to filter (sensitive data) | `['password', 'token', 'api_key', 'secret']` |
| `size_threshold_kb` | Maximum size (KB) for request/response bodies | `1024` (1MB) |
| `timeout_seconds` | Timeout for sending data to Levo.ai | `3` |
| `enabled` | Toggle to enable/disable the middleware | `true` |

## Advanced Usage

### Conditional Enabling

You may want to enable the middleware only in certain environments:

```ruby
# In config/initializers/levo_middleware.rb
LevoRailsMiddleware.configure do |config|
  config.remote_url = ENV['LEVO_MIDDLEWARE_URL']
  config.enabled = Rails.env.production? || Rails.env.staging?
end
```

### Custom Parameter Filtering

You can specify additional sensitive parameters to filter:

```ruby
LevoRailsMiddleware.configure do |config|
  config.filter_params = ['password', 'token', 'api_key', 'secret', 'ssn', 'credit_card']
end
```

### Traffic Sampling

For high-traffic applications, you can reduce the sampling rate:

```ruby
LevoRailsMiddleware.configure do |config|
  # Mirror only 10% of traffic
  config.sampling_rate = 0.1
end
```

## Troubleshooting

### Verifying Installation

To verify the middleware is properly installed, check your logs for entries containing `LEVO_MIRROR` when your application receives traffic.

### Common Issues

**No data appearing in Levo.ai dashboard**

1. Verify the `LEVO_MIDDLEWARE_URL` is correct
2. Check your application logs for any errors containing `LEVO_MIRROR`
3. Ensure the middleware is enabled and the sampling rate is > 0
4. Confirm your network allows outbound connections to the Levo.ai service

**Performance Impact**

The middleware is designed to have minimal impact on your application's performance. If you notice any impact:

1. Lower the sampling rate to reduce the number of mirrored requests
2. Increase the `exclude_paths` list to skip more endpoints
3. Reduce the `size_threshold_kb` to skip large payloads

## Support

For questions or issues, contact Levo.ai support at support@levo.ai or visit [help.levo.ai](https://help.levo.ai).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).