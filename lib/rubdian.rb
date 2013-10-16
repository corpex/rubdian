require "rubdian/version"
require "logger"
require "yaml"

module Rubdian
  @default = {}
  @default[:home] = "#{ENV['HOME']}/.rubdian"

  @default[:home] = "/etc/rubdian" if ENV['USER'] == "root"

  @default[:home] = ENV['RUBDIAN_HOME'] if ENV['RUBDIAN_HOME']

  @default[:config] = "#{@default[:home]}/rubdian.yml"

  @default[:source] = "#{@default[:home]}/server.list"

  @default[:source] = ENV['RUBDIAN_SOURCE'] if ENV['RUBDIAN_SOURCE']

  @default[:username] = ENV['USER']

  @default[:username] = ENV['SUDO_USER'] if ENV['SUDO_USER']

  @default[:username] = ENV['RUBDIAN_USER'] if ENV['RUBDIAN_USER']

  @default[:logdir] = "#{@default[:home]}/logs"

  @default[:logdir] = ENV['RUBDIAN_LOGDIR'] if ENV['RUBDIAN_LOGDIR']

  def self.default
    return @default
  end
  def self.load_config(file = @default[:config])
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

  def self.logger(out=STDOUT, rotate=nil)
        @logger = Logger.new(out, rotate) if ! @logger
        return @logger
  end
end
