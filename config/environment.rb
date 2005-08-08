RAILS_ROOT = File.dirname(__FILE__) + "/../"
RAILS_ENV  = ENV['RAILS_ENV'] || 'production'


# Mocks first.
ADDITIONAL_LOAD_PATHS = ["#{RAILS_ROOT}/test/mocks/#{RAILS_ENV}"]

# Then model subdirectories.
ADDITIONAL_LOAD_PATHS.concat(Dir["#{RAILS_ROOT}/app/models/[_a-z]*"])
ADDITIONAL_LOAD_PATHS.concat(Dir["#{RAILS_ROOT}/components/[_a-z]*"])

# Followed by the standard includes.
ADDITIONAL_LOAD_PATHS.concat %w(
  app
  app/models
  app/controllers
  app/helpers
  app/apis
  config
  components
  lib
  vendor
).map { |dir| "#{RAILS_ROOT}/#{dir}" }

# Prepend to $LOAD_PATH
ADDITIONAL_LOAD_PATHS.reverse.each { |dir| $:.unshift(dir) if File.directory?(dir) }


# Require Rails gems.
require 'rubygems'
require_gem 'activesupport'
require_gem 'activerecord'
require_gem 'actionpack'
require_gem 'actionmailer'
require_gem 'actionwebservice'
require_gem 'rails'

# Environment-specific configuration.
require_dependency "environments/#{RAILS_ENV}"
ActiveRecord::Base.configurations = YAML::load(File.open("#{RAILS_ROOT}/config/database.yml"))
ActiveRecord::Base.establish_connection


# Configure defaults if the included environment did not.
begin
  RAILS_DEFAULT_LOGGER = Logger.new("#{RAILS_ROOT}/log/#{RAILS_ENV}.log")
rescue StandardError
  RAILS_DEFAULT_LOGGER = Logger.new(STDERR)
  RAILS_DEFAULT_LOGGER.level = Logger::WARN
  RAILS_DEFAULT_LOGGER.warn(
    "Rails Error: Unable to access log file. Please ensure that log/#{RAILS_ENV}.log exists and is chmod 0666. " +
    "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed."
  )
end

[ActiveRecord, ActionController, ActionMailer].each { |mod| mod::Base.logger ||= RAILS_DEFAULT_LOGGER }
[ActionController, ActionMailer].each { |mod| mod::Base.template_root ||= "#{RAILS_ROOT}/app/views/" }
ActionController::Routing::Routes.reload

Controllers = Dependencies::LoadingModule.root(
  File.expand_path(File.join(RAILS_ROOT, 'app', 'controllers')),
  File.expand_path(File.join(RAILS_ROOT, 'components'))
)

# Include your app's configuration here:
def app_configurations
  YAML::load(File.open("#{RAILS_ROOT}/config/settings.yml"))
end
