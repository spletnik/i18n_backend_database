require 'rails/generators/active_record/migration'

class I18nBackendDatabaseGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  extend ActiveRecord::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)

  def create_migration
    migration_template "migrate/create_i18n_tables.rb", 'db/migrate/create_i18n_tables'
  end
end
