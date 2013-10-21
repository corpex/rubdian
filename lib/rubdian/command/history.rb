require "rubdian"
require "rubdian/trollop"
module Rubdian; module Command;
  module History
    def self.main(opts={})
      logger = Rubdian.logger
      lopts = Trollop::options do
        opt :limit, "Limit entries", :short => "-l", :default => 50
      end
      history = Rubdian::Command::History.filter().order(:begin).first(ltops[:limit])
      width_max = ENV['COLUMNS']
      printf("%s\n", "-" * width_max)

      printf("%s\n", "-" * width_max)

    end
  end
end;end
