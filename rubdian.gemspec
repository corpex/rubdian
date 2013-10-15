# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rubdian/version'

Gem::Specification.new do |spec|
  spec.name          = "rubdian"
  spec.version       = Rubdian::VERSION
  spec.authors       = ["Konrad Lother"]
  spec.email         = ["konrad@corpex.de"]
  spec.description   = %q{Manage debian update on remote systems.}
  spec.summary       = %q{Collect and update debian updates on several remote machines.}
  spec.homepage      = ""
  spec.license       = "GPLv2"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_dependency "cpx-distexec"
  spec.add_dependency "cpx-distexec-executor-ssh"
end
