require "sequel"
require "rubdian"

module Rubdian; module Database
  begin
    cfg = Rubdian.config['rubdian']['database']
    Rubdian.logger.debug("db cfg: #{cfg}")
    @db = Sequel.connect("#{cfg['uri']}") or abort "Could not connect to database!"

    if ! @db.table_exists? :nodes
      @db.create_table :nodes do
        primary_key :id
        String :hostname
        Fixnum :port
        TrueClass :blocked, :default => false
        TrueClass :queued, :default => false
        String :updates, :text => true, :default => nil
        String :blocks, :text => true, :default => nil
        DateTime :tstamp
      end
    end
    if ! @db.table_exists? :blacklist
      @db.create_table :blacklist do
        primary_key :id
        String :package
      end
    end
  rescue Sequel::DatabaseError => e
    $stderr.puts "Could not connect to database: #{e.message}"
    $stderr.puts "Did you ran 'rubdian setup'?"
    exit 1
  rescue Exception => e
    Rubdian.logger.error("Error while connecting to database: #{e.message}")
    exit 1
  end
  class Node < Sequel::Model(@db[:nodes]); end
  class Blacklist < Sequel::Model(@db[:blacklist]); end

end; end
