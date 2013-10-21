require "rubdian/version"
require "logger"
require "yaml"
require "colored"

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
  def self.load_config
    file = "#{@default[:home]}/rubdian.yml"
    _baseconfig = YAML.load_file("#{@default[:home]}/rubdian.yml")
    _cfgversion = _baseconfig['rubdian']['version']
    if _cfgversion.nil? or _cfgversion.empty? or (Gem::Version.new(Rubdian::VERSION) > Gem::Version.new(_cfgversion))
      puts "rubdian has detected that you're using an old rubdian.yml configuration file at\n\n"
      puts "#{file}\n\n"
      puts "that might not be compatible with this version of rubdian.\n\n"
      puts "Please upgrade rubdian.yml using the setup subcommand.\n\n"
      puts "Warning".red
      puts "This will overwrite the existing rubdian.yml and thus you might lose custom made changes.\n"
      puts "Please read to 'Configuration' chapter in rubdian's README to know how to keep them!\n\n"
      puts "rubdian will exit now and won't work unless you run setup again.\n\n"
      exit 1
    end
    _local = "#{@default[:home]}/rubdian.local.yml"
    if File.exists?(_local)
      _localconfig = YAML.load_file(_local)
      if _localconfig
        def self.confmerge(hsh1, hsh2)
          hsh1.each do |k, v|
            next if hsh2[k].nil?
            if v.class.to_s == Hash.to_s
              hsh1[k] = confmerge(hsh1[k], hsh2[k])
            else
              hsh1[k] = hsh2[k]
            end
          end
          return hsh1
        end
        _baseconfig = confmerge(_baseconfig, _localconfig)
      end
    end
    @config = _baseconfig
    return @config
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
