require 'i18n_backend_database'
require 'rails'

module I18nBackendDatabase
  class Railtie < Rails::Railtie
    railtie_name :i18n_backend_database

    rake_tasks do
      load File.join(File.dirname(__FILE__), '../tasks/i18n.rake')
    end
  end
end
