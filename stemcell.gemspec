# -*- encoding: utf-8 -*-
$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require "stemcell/version"

Gem::Specification.new do |gem|
  gem.name                        = "stemcell"
  gem.version                     = Bosh::Agent::StemCell::VERSION
  gem.authors                     = ["Ankur Chauhan", "Anfernee Yongkun Gui"]
  gem.email                       = ["ankurc@vmware.com", "agui@vmware.com"]
  gem.description                 = "Stemcell builder for Bosh"
  gem.summary                     = "A commandline utility for creating stemcells for Bosh [ http://www.github.com/ankurcha/stemcell ]"
  gem.homepage                    = "http://www.github.com/ankurcha/stemcell"
  gem.license                     = "MIT"

  gem.files                       = `git ls-files`.split($/)
  gem.bindir                      = "bin"
  gem.executables                 = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files                  = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths               = ["lib"]
  gem.required_rubygems_version   = ">= 1.3.6"
  gem.required_ruby_version       = Gem::Requirement.new(">= 1.9.3")

  # Dependencies
  gem.add_dependency                "veewee"
  gem.add_dependency                "net-ssh"
  gem.add_dependency                "vagrant"
  gem.add_dependency                "thor"
  gem.add_dependency                "deep_merge"
  gem.add_dependency                "logger-colors"
  gem.add_dependency                "kwalify"
  gem.add_dependency                "retryable"

  gem.add_development_dependency    "bundler"
  gem.add_development_dependency    "rake"
  gem.add_development_dependency    "rspec"
end
