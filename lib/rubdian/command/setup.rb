require "rubdian"
require "rubdian/version"
require "rubdian/trollop"
require "fileutils"
require "colored"

module Rubdian; module Command
  module Setup
    def self.main(opts = {})
      logger = Rubdian.logger
      logger.debug("Starting setup for rubdian #{Rubdian::VERSION}")


      default_dir = "#{ENV['HOME']}/.rubdian"
      isroot = false
      if ENV['user'] == "root"
        default_dir = '/etc/rubdian'
        isroot = true
      end

      logger.debug("Default install dir is #{default_dir}")

      lopts = Trollop::options do
        opt :directory, "Install rubdian configuration into this directory.", :short => "-d", :default => default_dir
      end

      puts "Welcome to rubdian setup\n\n"
      puts "You can cancel the installation anytime by pressing ctrl+c\n\n"

      spec = Gem::Specification.find_by_name("rubdian")
      gem_root = spec.gem_dir

      puts "Checking if rubdian directory #{lopts[:directory]} already exists"
      if ! Dir.exists?(lopts[:directory])
        begin
          puts "Creating rubdian directory at #{lopts[:directory]}"
          FileUtils.mkdir(lopts[:directory])
        rescue Exception, e
          $stderr.puts "Could not create directory #{lopts[:directory]}: #{e.message}"
          logger.error("Could not create directory #{lopts[:directory]}: #{e.message}")
        end
      end

      conffile = "#{lopts[:directory]}/rubdian.yml"
      conffile = "#{conffile}.dist" if File.exists?(conffile)

      puts "Installing default configuration file as #{conffile}"
      FileUtils.cp("#{gem_root}/share/rubdian.yml.dist", conffile)

    end
  end
end; end
