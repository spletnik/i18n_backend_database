require 'i18n_backend_database'
require 'rails'

module I18nBackendDatabase
  class Railtie < Rails::Railtie
    initializer "i18n_backend_database.initialize" do |app|
      I18n.backend = I18n::Backend::Database.new
    end

    rake_tasks do
      load File.join(File.dirname(__FILE__), '../tasks/i18n.rake')
    end
  end
end
