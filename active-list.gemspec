# encoding: utf-8
Gem::Specification.new do |s|
  s.name = "active-list"
  File.open("VERSION", "rb") do |f|
    s.version = f.read
  end
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.author = "Brice Texier"
  s.email  = "burisu@oneiros.fr"
  s.summary = "Easy tables in Rails app"
  s.description = "Generates action methods to"+
    " provide clean tables."
  s.extra_rdoc_files = [ "LICENSE", "README.rdoc" ]

  s.files = `git ls-files app lib locales VERSION LICENSE README.rdoc`.split("\n")
  s.homepage = "http://github.com/burisu/active-list"
  s.license = "MIT"
  s.require_path = "lib"

  s.add_dependency "rails", [">= 3.2", "< 4.1"]
  s.add_dependency "compass-rails", ["~> 1.1.7"]
  s.add_dependency "rubyzip", [">= 1.0"]
  s.add_dependency "fastercsv", [">= 1.5"]
  s.add_dependency "i18n-complements", [">= 0"]
  s.add_development_dependency("sqlite3", [">= 0"])
end

