require 'active_record'
require 'action_view'
require 'action_controller'
require 'rspec/rails'
require 'rails'
require 'i18n_backend_database'

ActiveRecord::Base.establish_connection(:adapter  => 'sqlite3',:database => ':memory:')
load 'generators/i18n_backend_database/templates/migrate/create_i18n_tables.rb'
CreateI18nTables.up
I18n.backend = I18n::Backend::Database.new(:cache_store => :memory_store)

RSpec.configure  do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false

  config.after(:each) do
    I18n::Backend::Locale.reset_default_locale
    I18n.locale = 'en'
    I18n.default_locale = 'en'
    I18n.backend.cache_store.clear
  end
end
