namespace :i18n do
  desc 'Clear cache'
  task :clear_cache => :environment do
    I18n.backend.cache_store.clear
  end

  desc 'Clear all translations'
  task :clear_all_translations => :environment do
    puts "REMOVING #{Translation.count}" if I18nUtil.verbose?
    Translation.delete_all
  end

  desc 'Clear translations that have no source'
  task :clear_no_source_translations => :environment do
    puts "REMOVING #{Translation.count(:conditions => {:source_id => nil})}" if I18nUtil.verbose?
    Translation.delete_all(:source_id => nil)
  end

  desc 'Clear translations whose source does not exist'
  task :clear_translations_with_missing_source => :environment do
    TranslationSource.all.each do |source|
      next unless source.path_not_found?

      puts "REMOVING #{Translation.count(:conditions => {:source_id => source.id})} FOR #{source.path}" if I18nUtil.verbose?
      Translation.delete_all(:source_id => source.id)
    end
  end

  desc 'Extracts translation data from database into fixtures'
  task :export_translations => :environment do
    locale_codes = ENV['LOCALE_CODES'] || I18n::Backend::Locale.non_defaults.collect{|locale| locale.code}.join(',')
    I18nUtil.process_translation_locales(locale_codes.split(',')) do |locale|
      I18nUtil.export_translations(locale)
    end
  end

  desc 'Load translation data from fixtures into database for a locale'
  task :import_translations => :environment do
    locale_codes = ENV['LOCALE_CODES'] || I18n::Backend::Locale.non_defaults.collect{|locale| locale.code}.join(',')
    I18nUtil.process_translation_locales(locale_codes.split(',')) do |locale|
      I18nUtil.import_translations(locale)
    end
  end

  desc 'Reset locales and translations from original sources and ready for 3rd-party translations'
  task :reset_locales_and_translations => %w(clear_all_translations populate:load_default_locales populate:from_rails populate:from_application clear_no_source_translations populate:synchronize_translations import_translations clear_cache)

  namespace :populate do
    I18nUtil.verbose = ENV['VERBOSE'] == 'true'

    desc 'Populate the locales and translations tables from all Rails Locale YAML files. Can set LOCALE_YAML_FILES to comma separated list of files to overide'
    task :from_rails => :environment do
      yaml_files = (ENV['LOCALE_YAML_FILES'] ? ENV['LOCALE_YAML_FILES'].split(',') : I18n.load_path).select{|path| path =~ /\.yml$/}
      yaml_files.each do |file|
        I18nUtil.load_from_yml file
      end
    end

    desc 'Populate the translation tables from translation calls within the application. This only works on basic text translations. Can set DIR to override starting directory.'
    task :from_application => :environment do
      dir = ENV['DIR'] ? ENV['DIR'] : "."
      I18nUtil.seed_application_translations(dir)
    end

    desc 'Create translation records from all default locale translations if none exists.'
    task :synchronize_translations => :environment do
      I18nUtil.synchronize_translations((ENV['SYNC_EXCLUDE'] || '').split(','))
    end

    desc 'Populate default locales'
    task :load_default_locales => :environment do
      I18nUtil.load_default_locales(ENV['LOCALE_FILE'])
    end

    desc 'Runs all populate methods in this order: load_default_locales, from_rails, from_application, synchronize_translations'
    task :all => %w(load_default_locales from_rails from_application synchronize_translations)
  end

  namespace :translate do
    desc 'Translate all untranslated values using Google Language Translation API.  Does not translate interpolated strings, date formats, or YAML'
    task :google => :environment do
      I18nUtil.google_translate
    end
  end
end
