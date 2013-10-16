require "rubdian/database"
require "rubdian"

module Rubdian; module Command
  module Blacklist
    def self.main(opts = {})
      logger = Rubdian.logger
      lopts = Trollop::options do
        opt :list, "List complete blacklist", :short => "-l"
        opt :add, "Add a new item to blacklist", :short => "-a"
        opt :delete, "Remove an item from blacklist", :short => "-d"
        opt :wipe, "Wipe blacklist", :short => "-w"
      end

      if lopts[:list]
        blacklist = Rubdian::Database::Blacklist.filter()
        blacklist.each do |b|
          puts "#{b[:package]}\n"
        end
        exit 0
      end

      if lopts[:add]
        ARGV.each do |arg|
          blacklist = Rubdian::Database::Blacklist.filter(:package => arg).first()
          if blacklist.nil?
            blacklist = Rubdian::Database::Blacklist.new
            blacklist.package = arg
            blacklist.save
            logger.debug("Added #{arg} to blacklist.")
          else
            logger.debug("Skipping #{arg}, already present.")
          end
        end
        exit 0
      end


      if lopts[:delete]
        ARGV.each do |arg|
          blacklist = Rubdian::Database::Blacklist.filter(:package => arg).first()
          if blacklist.nil?
            logger.debug("Can not remove #{arg}, not existent.")
            next
          end
          logger.debug("Removing #{arg} from blacklist.")
          blacklist.delete()
        end
      end

      if lopts[:wipe]
        raise Exception, "Not yet implemented."
      end
    end
  end
end; end
