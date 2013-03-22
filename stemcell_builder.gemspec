# -*- encoding: utf-8 -*-
$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require "stemcell/version"

Gem::Specification.new do |gem|
  gem.name                        = "stemcell_builder"
  gem.rubyforge_project           = "stemcell_builder"
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
  gem.required_rubygems_version   = ">= 1.3.6"
  gem.required_ruby_version       = Gem::Requirement.new(">= 1.9.3")
  gem.platform                    = Gem::Platform::RUBY

  # Dependencies  
  gem.add_dependency                "net-ssh", "~>2.6.6"
  gem.add_dependency                "net-scp", "~>1.1.0"
  gem.add_dependency                "thor", "~>0.17.0"
  gem.add_dependency                "deep_merge", "~>1.0.0"
  gem.add_dependency                "logger-colors", "~>1.0.0"
  gem.add_dependency                "kwalify", "~>0.7.2"
  gem.add_dependency                "retryable", "~>1.3.2"

  gem.add_development_dependency    "bundler", ">= 1.0.0"  
  gem.add_development_dependency    "rspec", "~> 2.5"
end
