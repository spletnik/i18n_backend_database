namespace :i18n do
  desc 'Clear cache'
  task :clear_cache => :environment do
    I18n.backend.cache_store.clear
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
    locale_codes = ENV['locale'] || I18n::Backend::Locale.all.map(&:code).join(',')
    I18nUtil.process_translation_locales(locale_codes.split(',')) do |locale, translation_path|
      translations = Translation.all :conditions => {:locale_id => locale.id}, :select => 'raw_key as `key`, value, pluralization_index'
      raise "No translations found for '#{locale.code}'" if translations.empty?
      puts "Export #{translations.length} translations for '#{locale.code}'..."
      FileUtils.mkpath(translation_path)
      File.open(translation_path + "#{locale.code}.yml",'w'){|file| file.write translations.collect{|entry| entry.attributes}.to_yaml}
    end
  end

  desc 'Load translation data from fixtures into database for a locale'
  task :import_translations => :environment do
    raise "Required argument: locale" unless ENV['locale']
    Rake::Task["i18n:clear_cache"].invoke
    I18nUtil.process_translation_locales(ENV['locale'].split(',')) do |locale, translation_path|
      translation_file = translation_path + "#{locale.code}.yml"
      raise "No translation file exists for '#{locale.code}' at #{translation_file}" unless File.exist?(translation_file)
      raise "No translations found for '#{locale.code}'" unless (translations = YAML::load_file(translation_file))
      puts "Importing #{translations.length} translations for '#{locale.code}'..."
      Translation.delete_all(:locale_id => locale.id)
      translations.each do |translation|
        Translation.create!(
          :key => translation['key'],
          :value => translation['value'],
          :pluralization_index => translation['pluralization_index'],
          :locale_id => locale.id
        )
      end
    end
  end

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
      I18nUtil.synchronize_translations
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
