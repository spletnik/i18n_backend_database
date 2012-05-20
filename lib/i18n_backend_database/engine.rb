module I18nBackendDatabase
  class Engine < Rails::Engine

    initializer "i18n_backend_database.initialize" do |app|
      I18n.backend = I18n::Backend::Database.new
    end

    initializer "common.init" do |app|
      # Publish #{root}/public path so it can be included at the app level
      if app.config.serve_static_assets
        app.config.middleware.use ::ActionDispatch::Static, "#{root}/public"
      end
    end

  end
end
