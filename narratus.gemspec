$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "narratus/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "narratus"
  s.version     = Narratus::VERSION
  s.authors     = ["Shane Wolf"]
  s.email       = ["shanewolf@gmail.com"]
  # s.homepage    = "Narratus: lightweight automatic instrumentation for analytics"
  s.summary     = "Narratus: lightweight automatic instrumentation for analytics"
  s.description = "Narratus: lightweight automatic instrumentation for analytics"
  s.license     = "MIT"

  s.files = Dir["{lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 4.2"

  s.add_development_dependency "sqlite3"
end
