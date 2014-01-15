require "rubdian"
require "rubdian/trollop"
require "rubdian/database"
require "curses"

module Rubdian; module Command;
  module History
    def self.main(opts={})
      logger = Rubdian.logger
      lopts = Trollop::options do
        opt :limit, "Limit entries", :short => "-l", :default => 0
      end
      if lopts[:limit] == 0
        history = Rubdian::Database::History.filter().order(:begin)
      else
        history = Rubdian::Database::History.filter().order(Sequel.desc(:end)).last(lopts[:limit])
      end
      width_max = `tput cols`.chomp.to_i
      line = "+#{"-" * (width_max - 2)}+"
      puts line
      puts line
      history.each do |h|
        printf("| %-20s | %-20s | %-10s | %-10s | %s |\n", h.begin, h.end, h.action, h.username, h.message)
      end
      puts line

    end
  end
end;end
