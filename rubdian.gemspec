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

  spec.required_ruby_version = '>= 1.9'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_dependency "cpx-distexec"
  spec.add_dependency "cpx-distexec-executor-ssh"
  spec.add_dependency "sequel"
  spec.add_dependency "colored"
  spec.add_dependency "sqlite3"
  spec.add_dependency "highline"

  spec.post_install_message = <<-EOF
Thank your for using rubdian #{Rubdian::VERSION}

If this is your first time installing rubdian, please run its setup
to complete the installation. This can be run either by root or as
a normal user.

To run the setup type

  $ rubdian setup

and follow the instructions.

NOTICE!!
If you experience problems with rubdian not being in your PATH,
uninstall rubdian and reinstall it with

  $ gem install --bindir /usr/local/bin rubdian

or change /usr/local/bin to whatever fits to you.

EOF
end
