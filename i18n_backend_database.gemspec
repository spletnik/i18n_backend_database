$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'i18n_backend_database/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'i18n_backend_database'
  s.version     = I18nBackendDatabase::VERSION
  s.authors     = ['Dylan Stamat']
  s.email       = ['dstamat@elctech.com']
  s.homepage    = 'http://someplace.com'
  s.summary     = 'summary.'
  s.description = 'description.'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['LICENSE', 'Rakefile', 'README.textile']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '>= 3'
  s.add_development_dependency 'rspec', '>= 2.0.0'
  s.add_development_dependency 'rspec-rails', '>= 2.0.0'
  s.add_development_dependency 'sqlite3', '>= 1.3.4'
end
