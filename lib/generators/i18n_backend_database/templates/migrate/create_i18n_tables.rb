class CreateI18nTables < ActiveRecord::Migration
  def up
    create_table :locales do |t|
      t.string   :code
      t.string   :name
    end
    add_index :locales, :code

    create_table :translations do |t|
      t.string   :key
      t.text     :raw_key
      t.text     :value
      t.integer  :pluralization_index, :default => 1
      t.integer  :locale_id
      t.integer  :source_id
    end
    add_index :translations, [:locale_id, :key, :pluralization_index]

    create_table :translation_sources do |t|
      t.string   :path
    end

  end

  def down
    drop_table :locales
    drop_table :translations
    drop_table :translation_sources
  end
end
