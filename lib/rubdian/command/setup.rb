require "rubdian"
require "rubdian/version"
require "rubdian/trollop"
require "fileutils"
require "sequel"

module Rubdian; module Command
  module Setup
    def self.main(opts = {})
      logger = Rubdian.logger
      logger.debug("Starting setup for rubdian #{Rubdian::VERSION}")

      lopts = Trollop::options do
        opt :directory, "Install rubdian configuration into this directory.", :short => "-d", :default => '/etc/rubdian'
      end


      if Dir.exists?(lopts[:directory])
        puts "#{lopts[:directory]} does already exist. You can use --directory to choose a different directory."
        puts "If you proceed, #{lopts[:directory]}/rubdian.yml will be overwritten. Continue? (y/N) "
        _in = gets.chomp
        exit 1 if _in.downcase != 'y'
      end

      spec = Gem::Specification.find_by_name("rubdian")
      gem_root = spec.gem_dir


      if ! Dir.exists?(lopts[:directory])
        puts "Creating #{lopts[:directory]}... "
        FileUtils.mkdir(lopts[:directory])
      end

      FileUtils.cp("#{gem_root}/share/rubdian.yml", lopts[:directory])

      puts "You can now run 'rubdian database' to install the database schema. Ensure to edit #{lopts[:directory]} before!"
    end
  end
end; end
