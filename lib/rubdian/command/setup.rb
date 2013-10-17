require "rubdian"
require "rubdian/version"
require "rubdian/trollop"
require "fileutils"
require "colored"
require "yaml"
module Rubdian; module Command
  module Setup
    def self.main(opts = {})
      lopts = Trollop::options do
        opt :directory, "Install rubdian configuration into this directory.", :short => "-d", :default => Rubdian.default[:home]
        version "rubdian #{Rubdian::VERSION} (c) 2013 CORPEX Internet GmbH"
      end

      puts "Welcome to rubdian #{Rubdian::VERSION} setup\n".bold

      spec = Gem::Specification.find_by_name("rubdian")
      gem_root = spec.gem_dir

      puts "Checking if rubdian directory #{lopts[:directory]} already exists"
      if ! File.exists?(lopts[:directory])
        begin
          puts "Creating rubdian directory at #{lopts[:directory]}"
          FileUtils.mkdir(lopts[:directory])
          puts "Creating log directory #{lopts[:directory]}/logs"
          FileUtils.mkdir("#{lopts[:directory]}/logs")
        rescue Exception, e
          $stderr.puts "Could not create directory #{lopts[:directory]}: #{e.message}"
        end
      end

      _cfg = "#{lopts[:directory]}/rubdian.yml"
      distconf = "#{_cfg}.dist"

      puts "Installing default configuration file as #{distconf}\n\n"
      FileUtils.cp("#{gem_root}/share/rubdian.yml.dist", distconf)

      cfg = YAML.load_file(distconf)
      cfg['rubdian']['database']['url'] = "sqlite://#{lopts[:directory]}/rubdian.db"
      File.open(_cfg, "w+") do |f|
        f.write(cfg.to_yaml)
      end
      puts "#" * 80
      puts "\nInstallation complete!".bold
      puts "rubdian is using sqlite3 as its default database."
      puts "If you want to change its database driver, please edit\n\n"
      puts "\t#{_cfg}\n".bold
      puts "and change the database connection url. rubdian will\n"
      puts "automatically install its database schema if possible.\n\n"
      puts "A default configuration file has been generated to\n\n"
      puts "\t#{_cfg}\n".bold
      puts "without comments. To create your very own configuration,\ncopy\n\n"
      puts "\t#{distconf}\n".bold
      puts "and start editing.\n\n"
      puts "Please report bugs to bugs+rubdian@corpex.de\n\n"
    end
  end
end; end
