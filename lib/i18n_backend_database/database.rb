require_relative '../i18n_util'

module I18n::Backend
  class Database
    INTERPOLATION_RESERVED_KEYS = %w(scope default)
    MATCH = /(\\\\)?%\{([^\}]+)\}/

    attr_accessor :locale
    attr_accessor :cache_store
    attr_accessor :localize_text_tag

    def initialize(options = {})
      store = options.delete(:cache_store)
      text_tag = options.delete(:localize_text_tag)
      @cache_store = store ? ActiveSupport::Cache.lookup_store(store) : Rails.cache
      @localize_text_tag = text_tag ? text_tag : '^^'
    end

    def locale=(code)
      @locale = I18n::Backend::Locale.find_by_code(code)
    end

    def cache_store=(store)
      @cache_store = ActiveSupport::Cache.lookup_store(store)
    end

    # TODO RAILS3 not sure what this method should do or how it should act yet
    def transliterate *args
      args[1]
    end

    # Handles the lookup and addition of translations to the database
    #
    # On an initial translation, the locale is checked to determine if
    # this is the default locale.  If it is, we'll create a complete
    # translation record for this locale with both the key and value.
    #
    # If the current locale is checked, and it differs from the default
    # locale, we'll create a translation record with a nil value.  This
    # allows for the lookup of untranslated records in a given locale.
    def translate(locale, key, options = {})
      locale_in_context(locale)

      options[:scope] = [options[:scope]] unless options[:scope].is_a?(Array) || options[:scope].blank?
      key = "#{options[:scope].join('.')}.#{key}".to_sym if options[:scope]
      count = options[:count]
      # pull out values for interpolation
      values = options.reject { |name, value| [:scope, :default].include?(name) }

      entry = lookup(@locale, key)
      cache_lookup = true unless entry.nil?

      # if no entry exists for the current locale and the current locale is not the default locale then lookup translations for the default locale for this key
      unless entry || @locale.default_locale?
        entry = use_and_copy_default_locale_translations_if_they_exist(@locale, key)
      end

      # TODO revisit this code -- for now consider the first non-Symbol default as the value
      # if we have no entry and some defaults ... start looking them up
      #unless entry || key.is_a?(String) || options[:default].blank?
      #  default = options[:default].is_a?(Array) ? options[:default].shift : options.delete(:default)
      #  return translate(@locale.code, default, options.dup)
      #end

      # this needs to be folded into the above at some point.
      # this handles the case where the default of the string key is a space
      if !entry && key.is_a?(String) && options[:default] == " "
        default = options[:default].is_a?(Array) ? options[:default].shift : options.delete(:default)
        return translate(@locale.code, default, options.dup)
      end

      # The requested key might not be a parent node in a hierarchy of keys instead of a regular 'leaf' node
      #   that would simply result in a string return.  If so, check the database for possible children
      #   and return them in a nested hash if we find them.
      #   We can safely ignore pluralization indeces here since they should never apply to a hash return
      if !entry && (key.is_a?(String) || key.is_a?(Symbol))
        #We need to escape % and \.  Rails will handle the rest.
        escaped_key = key.to_s.gsub('\\', '\\\\\\\\').gsub(/%/, '\%')
        # Only taking those translations that in which the beggining of the raw_key is EXACTLY like the given case. This means it's not case sensitive.
        # This allows to use Number as a normal key and number.whatever.whatever.. as the scoped key.
        children = @locale.translations.where(["raw_key like ?", "#{escaped_key}.%"]).select{|child| child.raw_key.starts_with?(key.to_s)}
        if children.size > 0
          entry = hashify_record_array(key.to_s, children)
          @cache_store.write(Translation.ck(@locale, key), entry) unless cache_lookup == true
          return entry
        end
      end

      # we check the database before creating a translation as we can have translations with nil values
      # if we still have no blasted translation just go and create one for the current locale!
      unless entry
        pluralization_index = (options[:count].nil? || options[:count] == 1) ? 1 : 0
        key = key.to_s
        key.gsub!('.one', '') if key.ends_with?('.one')
        if (translation = @locale.translations.find_by_key_and_pluralization_index(Translation.hk(key), pluralization_index)) and not translation.raw_key.starts_with?(key.to_s)
          translation = nil
        end
        unless translation
          first_string_default = Array(options[:default]).detect{|option| option.is_a?(String)}
          translation = @locale.create_translation(key, first_string_default || key, pluralization_index)
        end
        entry = translation.value_or_default
      end

      # write to cache unless we've already had a successful cache hit
      @cache_store.write(Translation.ck(@locale, key), entry) unless cache_lookup == true

      entry = pluralize(@locale, entry, count)
      entry = interpolate(@locale.code, entry, values)
      entry.is_a?(Array) ? entry.dup : entry # array's can get frozen with cache writes
    end

    # Acts the same as +strftime+, but returns a localized version of the
    # formatted date string. Takes a key from the date/time formats
    # translations as a format argument (<em>e.g.</em>, <tt>:short</tt> in <tt>:'date.formats'</tt>).
    def localize(locale, object, format = :default, options = {})
      raise ArgumentError, "Object must be a Date, DateTime or Time object. #{object.inspect} given." unless object.respond_to?(:strftime)

      locale_in_context(locale)

      if format.to_s.index('%')
        format = format.dup # ensure that the original format (possibly a constant) is not modified
      else # Unless a custom format is passed
        type = object.respond_to?(:sec) ? 'time' : 'date'
        if lookup(@locale, "#{type}.formats.#{format.to_s}") # Translation is in the database
          format = translate(locale, "#{type}.formats.#{format.to_s}") # lookup keyed formats
        else # There is no localization translations on the database, loading the default ones
          I18nUtil.load_default_localizations
          locale = I18n::Backend::Locale.default_locale.code
          format = translate(locale, "#{type}.formats.#{format.to_s}")
        end
      end

      format = format.dup
      format.gsub!(/%a/, translate(locale, "date.abbr_day_names")[object.wday])
      format.gsub!(/%A/, translate(locale, "date.day_names")[object.wday])
      format.gsub!(/%b/, translate(locale, "date.abbr_month_names")[object.mon])
      format.gsub!(/%B/, translate(locale, "date.month_names")[object.mon])
      format.gsub!(/%p/, translate(locale, "time.#{object.hour < 12 ? :am : :pm}")) if object.respond_to? :hour

      object.strftime(format)
    end

    # Returns the text string with the text within the localize text tags translated.
    def localize_text(locale, text)
      text_tag    = Regexp.escape(localize_text_tag).to_s
      expression  = Regexp.new(text_tag + "(.*?)" + text_tag)
      tagged_text = text[expression, 1]
      while tagged_text do
        text = text.sub(expression, translate(locale, tagged_text))
        tagged_text = text[expression, 1]
      end
      return text
    end

    def available_locales
      I18n::Backend::Locale.available_locales
    end

    def reload!
      # get's called on initialization
      # let's not do anything yet
    end

    # lookup key in cache and db, if the db is hit the value is cached
    def lookup(locale, key)
      cache_key = Translation.ck(locale, key)
      if @cache_store.exist?(cache_key) && value = @cache_store.read(cache_key)
        return value
      else
        translations = locale.translations.find_all_by_key(Translation.hk(key)).select{|translation| translation.raw_key.starts_with?(key.to_s)}
        case translations.size
        when 0
          value = nil
        when 1
          value = translations.first.value_or_default
        else
          value = translations.inject([]) do |values, t|
            values[t.pluralization_index] = t.value_or_default
            values
          end
        end
        @cache_store.write(cache_key, (value.nil? ? nil : value))
        return value
      end
    end

  protected
    # keep a local copy of the locale in context for use within the translation
    # routine, and also accept an arbitrary locale for one time locale lookups
    def locale_in_context(locale)
      return @locale if @locale && @locale.code == locale.to_s
      return @locale unless locale.class == String || locale.class == Symbol
      @locale = I18n::Backend::Locale.find_or_create_by_code(locale.to_s)
      raise I18n::InvalidLocale.new(locale) unless @locale
    end

    # looks up translations for the default locale, and if they exist untranslated records are created for the locale and the default locale values are returned
    def use_and_copy_default_locale_translations_if_they_exist(locale, key)
      default_locale_entry = lookup(I18n::Backend::Locale.default_locale, key)
      return unless default_locale_entry

      if default_locale_entry.is_a?(Array)
        default_locale_entry.each_with_index do |entry, index|
          locale.create_translation(key, nil, index) if entry
        end
      else
        locale.create_translation(key, nil)
      end

      return default_locale_entry
    end

    def pluralize(locale, entry, count)
      return entry unless entry.is_a?(Array) and count
      count = count == 1 ? 1 : 0
      entry.compact[count]
    end

    # Interpolates values into a given string.
    # 
    #   interpolate "file %{file} opened by \\%{user}", :file => 'test.txt', :user => 'Mr. X'
    #   # => "file test.txt opened by %{user}"
    # 
    # Note that you have to double escape the <tt>\\</tt> when you want to escape
    # the <tt>%{...}</tt> key in a string (once for the string and once for the
    # interpolation).
    def interpolate(locale, string, values = {})
      return string unless string.is_a?(String)

      string = string.dup # It returns an error if not duplicated

      if string.respond_to?(:force_encoding)
        original_encoding = string.encoding
        string.force_encoding(Encoding::BINARY)
      end

      result = string.gsub(MATCH) do
        escaped, pattern, key = $1, $2, $2.to_sym
        if escaped
          pattern
        elsif INTERPOLATION_RESERVED_KEYS.include?(pattern)
          raise ReservedInterpolationKey.new(pattern, string)
        elsif !values.include?(key)
          raise MissingInterpolationArgument.new(pattern, string)
        else
          values[key].to_s
        end
      end

      result.force_encoding(original_encoding) if original_encoding
      result
    end

    def strip_root_key(root_key, key)
      return nil if key.nil?
      return key.gsub(/^#{root_key}\./, '')
    end

    def hashify_record_array(root_key, record_array)
      return nil if record_array.nil? || record_array.empty?

      #Make sure that all of our records have raw_keys
      record_array.reject! {|record| record.raw_key.nil?}

      # Start building our return hash
      result = {}
      record_array.each do |record|
        key = strip_root_key(root_key, record.raw_key)
        next unless key.present?

        # If we contain a period delimiter, we need to add a sub-hash.
        # Otherwise, we just insert the value at this level.
        if key.index(".")
          internal_node = key.slice(0, key.index('.'))
          new_root = root_key + '.' + internal_node
          new_record_array = record_array.select {|record| record.raw_key.starts_with? new_root}
          result[internal_node.to_sym] = hashify_record_array(new_root, new_record_array)
        else
          value = record.value
          value = value.to_i if value == "0" || value.to_i != 0 #simple integer cast
          result[key.to_sym] = value
        end
      end
      result
    end
  end
end
