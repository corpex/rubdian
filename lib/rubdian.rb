require "rubdian/version"
require "logger"

module Rubdian

  def self.load_hosts
    logger = Rubdian.logger
  end

  def self.collect()
    logger = Rubdian.logger

  end

  def self.logger(out=STDOUT)
        @logger = Logger.new(out) if ! @logger
        return @logger
  end
end
