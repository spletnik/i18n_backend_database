module I18n::Backend
  class Locale < ActiveRecord::Base
    validates_presence_of :code
    validates_uniqueness_of :code

    has_many :translations, :dependent => :destroy
    scope :non_defaults, :conditions => ["code != ?", I18n.default_locale.to_s]

    # scope :english, lambda { |m| { return Hash.new if m.nil?; :conditions => "locales.locale = '#{m}'" } }
    # scope :in_city, lambda { |m| { return {} if m.nil?; :joins => [cities], :conditions => "cities.name = '#{m}' } }
    
    def self.default_locale
      @@default_locale ||= self.find(:first, :conditions => {:code => I18n.default_locale.to_s})
    end

    def self.reset_default_locale
      @@default_locale = nil
    end

    def translation_from_key(key)
      self.translations.find(:first, :conditions => {:key => Translation.hk(key)})
    end

    def create_translation(key, value, pluralization_index=1)
      conditions = {:key => key, :raw_key => key.to_s, :pluralization_index => pluralization_index, :source_id => I18nUtil.current_load_source.to_param}

      # set the key as the value if we're using the default locale and the key is a string
      conditions.merge!({:value => value}) if (self.code == I18n.default_locale.to_s && key.is_a?(String))
      translation = self.translations.create(conditions)
      puts "...NEW #{self.code} : #{key} : #{pluralization_index}" if I18nUtil.verbose?

      # hackity hack.  bug #922 maybe?
      self.connection.commit_db_transaction unless Rails.env.test?
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
