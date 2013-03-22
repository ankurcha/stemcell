# -*- encoding: utf-8 -*-
$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require "stemcell/version"

Gem::Specification.new do |gem|
  gem.name                        = "stemcell_builder"  
  gem.version                     = Bosh::Agent::StemCell::VERSION
  gem.authors                     = ["Ankur Chauhan"]
  gem.email                       = ["ankur@malloc64.com"]
  gem.description                 = "Stemcell builder for Bosh"
  gem.summary                     = "A commandline utility for creating stemcells for Bosh [ http://www.github.com/cloudfoundry/bosh ]"
  gem.homepage                    = "http://www.github.com/ankurcha/stemcell"
  gem.license                     = "MIT"

  gem.files                       = `git ls-files`.split($/)
  gem.bindir                      = "bin"
  gem.executables                 = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files                  = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths               = ["lib"]
  
  gem.platform                    = Gem::Platform::RUBY
  gem.required_rubygems_version   = ">= 1.3.6"
  gem.rubyforge_project           = "stemcell_builder"  

  # Dependencies  
  gem.add_dependency                "net-ssh"
  gem.add_dependency                "net-scp"
  gem.add_dependency                "thor"
  gem.add_dependency                "deep_merge"
  gem.add_dependency                "logger-colors"
  gem.add_dependency                "kwalify"
  gem.add_dependency                "retryable"

  gem.add_development_dependency    "bundler"
  gem.add_development_dependency    "rspec"
  gem.add_development_dependency    "veewee"
  gem.add_development_dependency    "vagrant"
end
