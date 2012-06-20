ENV['RAILS_ENV'] = 'test'

require 'active_record'
require 'action_view'
require 'action_controller'
require 'rspec/rails'
require 'rails'

ActiveRecord::Base.establish_connection(:adapter  => 'sqlite3',:database => ':memory:')
ActiveRecord::Migrator.up File.dirname(__FILE__) + '/migrations'

class Application < Rails::Application
end

Application.configure do
  config.cache_store = :memory_store
  config.active_support.deprecation = :log
end

Application.initialize!

require 'i18n_backend_database'

I18n.backend = I18n::Backend::Database.new

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.use_instantiated_fixtures  = false

  config.after(:each) do
    I18n::Backend::Locale.reset_default_locale
    I18n.locale = 'en'
    I18n.default_locale = 'en'
    I18n.backend.cache_store.clear
  end
end
