Dir[File.dirname(__FILE__) + '/../app/**/*.rb'].each{|file| require file}
require File.dirname(__FILE__) + '/i18n_backend_database/database'
require File.dirname(__FILE__) + '/ext/i18n'
require File.dirname(__FILE__) + '/i18n_util'
require File.dirname(__FILE__) + '/i18n_backend_database'

require 'i18n_backend_database/engine'
