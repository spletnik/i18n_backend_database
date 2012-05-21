class TranslationSource < ActiveRecord::Base

  def full_path
    @full_path ||= self.path && (Rails.root + self.path)
  end

  def path_not_found?
    full_path && !full_path.exist?
  end
end
