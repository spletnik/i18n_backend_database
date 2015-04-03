# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'i18n_backend_database/version'

Gem::Specification.new do |spec|
  spec.name          = "i18n_backend_database"
  spec.version       = I18nBackendDatabase::VERSION
  spec.authors       = ["Vladan Markovic"]
  spec.email         = ["vladanm@gmail.com"]
  spec.summary       = %q{Write a short summary. Required.}
  spec.description   = %q{Write a longer description. Optional.}
  #spec.description   = %q{Internationalize numbers adding normalization, validation and modifying the number field to restor the value to its original if validation fails}
  #spec.summary       = gem.description
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
