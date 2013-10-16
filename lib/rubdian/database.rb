require "sequel"
require "rubdian"

module Rubdian; module Database
  dbcfg = Rubdian.config['rubdian']['database']
  @db = Sequel.connect("#{dbcfg['driver']}://#{dbcfg['username']}:#{dbcfg['password']}@#{dbcfg['hostname']}/#{dbcfg['database']}") or abort "Could not connect to database!"
  class Node < Sequel::Model(@db[:nodes])
  class Blacklist < Sequel::Model(@db[:blacklist])

end; end
