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
#        opt :directory, "Install rubdian configuration into this directory.", :short => "-d", :default => '/etc/rubdian'
      end
      cfg = Rubdian.config['rubdian']['database']
      db = Sequel.connect("#{cfg['driver']}://#{cfg['username']}:#{cfg['password']}@#{cfg['hostname']}/#{cfg['database']}") or abort "Could not connect to database!"

      if ! db.table_exists? :nodes
        db.create_table :nodes do
          primary_key :id
          String :hostname
          Fixnum :port
          TrueClass :blocked, :default => nil
          TrueClass :queued, :default => nil
          String :updates, :text => true, :default => nil
          String :blocks, :text => true, :default => nil
          DateTime :tstamp
        end
      end
      if ! db.table_exists? :blacklist
        db.create_table :blacklist do
          primary_key :id
          String :package
        end
      end
    end
  end
end; end
