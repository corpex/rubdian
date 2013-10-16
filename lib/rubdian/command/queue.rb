require "rubdian"
require "rubdian/database"

module Rubdian; module Command
  module Queue
    def self.main(opts = {})
      lopts = Trollop::options do
        opt :all, "Queue all hosts for updates (except blocked ones)"
        opt :add, "Queue a certain host.", :short => "-a"
      end
    end
  end
end; end
