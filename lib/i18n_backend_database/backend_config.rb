# This is where the i18n backend handler is overriden
module I18n
  Config.class_eval do
    def backend
      @@backend ||= Backend::Database.new # Backend::Simple.new
    end
  end
end
