require "rubdian"
require "rubdian/version"
require "rubdian/trollop"
require "fileutils"
require "sequel"

module Rubdian; module Command
  module Database
    def self.main(opts = {})
      logger = Rubdian.logger
      logger.debug("Starting setup for rubdian #{Rubdian::VERSION}")

      lopts = Trollop::options do
        opt :directory, "Install rubdian configuration into this directory.", :short => "-d", :default => '/etc/rubdian'
      end
      cfg = Rubdian.config['rubdian']['database']
      puts cfg
    end
  end
end; end
