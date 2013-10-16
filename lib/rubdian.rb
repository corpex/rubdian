require "rubdian/version"
require "logger"
require "yaml"

module Rubdian

  def self.load_config(file = '/etc/rubdian/rubdian.yml')
    @config = YAML.load_file(file)
  end

  def self.config
    Rubdian.load_config if ! @config
    return @config
  end

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
