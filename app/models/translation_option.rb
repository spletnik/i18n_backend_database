class TranslationOption

  attr_accessor :code, :description
  cattr_accessor :translated, :untranslated, :unsourced

  def initialize(code, description)
    @code, @description = code, description
  end

  def self.all
    [untranslated, translated, unsourced]
  end

  def self.translated
    @@translated ||= TranslationOption.new('translated', 'Translated')
  end

  def self.untranslated
    @@untranslated ||= TranslationOption.new('untranslated', 'Untranslated')
  end

  def self.unsourced
    @@unsourced ||= TranslationOption.new('unsourced', 'Unsourced')
  end

  def self.find(code)
    all.detect{|option| option.code == code} || untranslated
  end

end