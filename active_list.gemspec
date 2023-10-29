require_relative 'lib/active_list/version'

Gem::Specification.new do |spec|
  spec.name = 'active_list'
  spec.version = ActiveList::VERSION
  spec.author = 'Brice Texier'
  spec.email = 'burisu@oneiros.fr'
  spec.summary = 'Simple interactive tables for Rails app'
  spec.description = 'Generates action methods to provide clean tables.'
  spec.homepage = 'http://gitlab.com/ekylibre/active_list'
  spec.license = 'MIT'

  spec.files = `git ls-files -z app lib locales LICENSE.txt README.rdoc test`.split("\x0")
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 1.9.3'

  spec.add_dependency 'code_string', ['>= 0.0.2']
  spec.add_dependency 'i18n-complements', ['>= 1.1.0']
  spec.add_dependency 'onoma', '~> 0.4'
  spec.add_dependency 'rails', ['6.0.6.1']
  # spec.add_dependency 'rails', ['>= 3.2', '< 6']
  spec.add_dependency 'rodf', '~> 1.1'
  spec.add_dependency 'rubyzip', ['>= 1.0']

  spec.add_development_dependency('sqlite3', ['~> 1.4'])
  # spec.add_development_dependency('sqlite3', ['~> 1.3.6'])

  spec.add_development_dependency('minitest', "~> 5.20.0")
  spec.add_development_dependency('minitest-reporters', '~> 1.4')
end
