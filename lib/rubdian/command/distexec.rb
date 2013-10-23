require "rubdian"
require "rubdian/trollop"
require "rubdian/database"

module Rubdian; module Command;
  module Distexec
    def self.main(opts={})
      logger = Rubdian.logger
      lopts = Trollop::options do
        opt :limit, "Limit entries", :short => "-l", :default => 0
      end

    end
  end
end;end
