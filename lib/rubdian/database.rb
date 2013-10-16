require "sequel"
require "rubdian"

module Rubdian; module Database
  dbcfg = Rubdian.config['rubdian']['database']
  begin
    @db = Sequel.connect("#{dbcfg['driver']}://#{dbcfg['username']}:#{dbcfg['password']}@#{dbcfg['hostname']}/#{dbcfg['database']}") or abort "Could not connect to database!"
  rescue Sequel::DatabaseError, e
    $stderr.puts "Could not connect to database: #{e.message}"
    $stderr.puts "Did you ran 'rubdian setup'?"
    exit 1
  rescue Exception, e
    Rubdian.logger.error("Error while connecting to database: #{e.message}")
  end
  class Node < Sequel::Model(@db[:nodes]); end
  class Blacklist < Sequel::Model(@db[:blacklist]); end

end; end
