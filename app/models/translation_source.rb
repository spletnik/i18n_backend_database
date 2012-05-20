class TranslationSource < ActiveRecord::Base

  def full_path
    @full_path ||= self.app_root ? Pathname.new(Rails.root.to_s + self.path) : self.path ? Pathname.new(self.path) : nil
  end

  def path_not_found?
    full_path && !full_path.exist?
  end
end
