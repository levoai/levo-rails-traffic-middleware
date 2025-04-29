# levo_rails_middleware.gemspec
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'levo_rails_middleware/version'

Gem::Specification.new do |spec|
  spec.name          = "levo_rails_middleware"
  spec.version       = LevoRailsmiddleware::VERSION
  spec.authors       = ["Levo.ai Team"]
  spec.email         = ["support@levo.ai"]

  spec.summary       = %q{API traffic middlewareing middleware for Rails applications}
  spec.description   = %q{A Rails middleware for Levo.ai customers that captures HTTP requests and responses and sends them to Levo.ai for API security analysis}
  spec.homepage      = "https://github.com/levoai/levo-rails-middleware"
  spec.license       = "MIT"

  spec.files         = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md)
  spec.require_paths = ["lib"]

  spec.add_dependency "rack", ">= 1.6.0" 
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end