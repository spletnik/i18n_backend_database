module I18n::Backend
  class Locale < ActiveRecord::Base
    validates_presence_of :code
    validates_uniqueness_of :code

    has_many :translations, :dependent => :destroy
    scope :non_defaults, -> { where("code != ?", I18n.default_locale.to_s) }

    # scope :english, lambda { |m| { return Hash.new if m.nil?; :conditions => "locales.locale = '#{m}'" } }
    # scope :in_city, lambda { |m| { return {} if m.nil?; :joins => [cities], :conditions => "cities.name = '#{m}' } }
    
    def self.default_locale
      @@default_locale ||= where(:code => I18n.default_locale.to_s).first
    end

    def self.reset_default_locale
      @@default_locale = nil
    end

    def self.find_or_create!(params)
      code = params.kind_of?(Hash) ? params[:code] : params.to_s
      where(:code => code).first || create!(:code => code)
    end

    def translation_from_key(key)
      self.translations.where(:key => Translation.hk(key)).first
    end

    def create_translation(key, value, pluralization_index=1)
      conditions = {:key => key, :raw_key => key.to_s, :pluralization_index => pluralization_index}

      conditions[:source_id] = I18nUtil.current_load_source.to_param if Translation.column_names.include?('source_id') # TODO does this NEED to happen? occurs when adding "source_id" migration to legacy installs

      # set the key as the value if we're using the default locale and the key is a string
      conditions.merge!({:value => value}) if (self.code == I18n.default_locale.to_s && key.is_a?(String))
      translation = self.translations.create(conditions)
      puts "...NEW #{self.code} : #{key} : #{pluralization_index}" if I18nUtil.verbose?

      # hackity hack.  bug #922 maybe?
      #self.connection.commit_db_transaction unless Rails.env.test?
      translation
    end

    def find_translation_or_copy_from_default_locale(key, pluralization_index)
      self.translations.find_by_key_and_pluralization_index(Translation.hk(key), pluralization_index) || copy_from_default(key, pluralization_index)
    end

    def copy_from_default(key, pluralization_index)
      if !self.default_locale? && I18n::Backend::Locale.default_locale.has_translation?(key, pluralization_index)
        create_translation(key, key, pluralization_index)
      end
    end

    def has_translation?(key, pluralization_index=1)
      self.translations.exists?(:key => Translation.hk(key), :pluralization_index => pluralization_index)
    end

    def percentage_translated
      (self.translations.translated.count.to_f / self.translations.count.to_f * 100).round rescue 100
    end

    def self.available_locales
      all.map(&:code).map(&:to_sym) rescue []
    end

    def default_locale?
      self == I18n::Backend::Locale.default_locale
    end

    def to_param
      self.code
    end
  end
end
