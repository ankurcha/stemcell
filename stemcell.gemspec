# -*- encoding: utf-8 -*-
$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require "builders/version"

Gem::Specification.new do |gem|
  gem.name                        = "stemcell"
  gem.version                     = Bosh::Agent::StemCell::VERSION
  gem.authors                     = ["Ankur Chauhan"]
  gem.email                       = %w(ankurc@vmware.com)
  gem.description                 = "Write a description"
  gem.summary                     = "Write a summary"
  gem.homepage                    = "http://www.github.com/cloudfoundry/bosh"
  gem.license                     = 'Apache 2.0'

  gem.files                       = `git ls-files`.split($/)
  gem.executables                 = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files                  = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths               = %w(lib)
  gem.required_rubygems_version   = ">= 1.3.6"
  gem.required_ruby_version       = Gem::Requirement.new(">= 1.9.3")

  # Dependencies
  gem.add_dependency "veewee"
  gem.add_dependency "vagrant"
  gem.add_dependency "thor"
  gem.add_dependency "deep_merge"

  gem.add_development_dependency "bundler"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
end
