require "cpx/distexec"
require "cpx/distexec/executor/ssh"
require "rubdian"
require "logger"
require "rubdian/database"
module Rubdian; module Command
  module Collect
    def self.main(opts = {})
      logger = Rubdian.logger
      cfg = Rubdian.config

      require cfg['rubdian']['distexec']['backend']['require']
      _beclass = eval(cfg['rubdian']['distexec']['backend']['driver']) # dirty
      Cpx::Distexec.logger.level = Logger::ERROR
      if ! File.exists?(opts[:source])
        $stderr.puts "source file #{opts[:source]} not found."
        exit 1
      end
      Cpx::Distexec.set_backend(_beclass, :file => opts[:source])
      Cpx::Distexec.set_executor(Cpx::Distexec::Executor::SSH, :username => opts[:username], :timeout => 4, :user_known_hosts_file => '/dev/null')

      Cpx::Distexec.load_nodes


      _blacklist = Rubdian::Database::Blacklist.filter()
      blacklist = []
      _blacklist.each do |b|
        blacklist << b.package
      end
      logger.debug("Using #{cfg['rubdian']['commands']['collect']} to collect updates...")
      Cpx::Distexec.exec(cfg['rubdian']['commands']['collect'], :concurrent => opts[:concurrent], :execution_timeout => 160) do |node, executor|

        _log = "#{Rubdian.default[:logdir]}/#{node.hostname}.log"
        logger.info(node.hostname) { "Collecting updates for #{node.hostname}, logging to #{_log}" }
        _logger = Logger.new(_log)
        _logger.level = Rubdian.logger.level
        puts "Starting collect on #{node.hostname}"
        _hl = "-" * 80
        _start = Time.now
        _logger.info(_hl)
        _logger.info("Starting collect on #{Time.now}")
        _logger.info("Using command: #{cfg['rubdian']['commands']['collect']}")

        n = Rubdian::Database::Node.filter(:hostname => node.hostname).first()
        if n.nil?
          n = Rubdian::Database::Node.new
          n.hostname = node.hostname
          if ! node.port.nil?
            n.port = node.port
          end
        end
        _blocks = []
        _updates = []
        executor.on_data do |data, type|
          # grabbing install data
          data = data.chomp
          data = data.lstrip
          data = data.rstrip
          s = data.split("\n")
          s.each do |data|
            _logger.debug(data)
            if data =~/^Inst/
              spl = data.split(" ", 3)
              pkg = spl[1]
              _spl = spl[2].split(" ", 3)
              _curVersion = _spl[0]
              _newVersion = _spl[1]
              _curVersion = _curVersion.delete "["
              _curVersion = _curVersion.delete "]"
              _newVersion = _newVersion.delete "("
              _logger.info("Update #{pkg}: #{_curVersion} to #{_newVersion}")
              _blocked = false
              blacklist.each do |b|
                _logger.debug("Comparing #{pkg} with #{b}...")
                if pkg.match(b)
                  _logger.warn("Blocking #{pkg} (#{b})")
                  _blocks.push(pkg)
                  _blocked = true
                  n.blocked = true
                  break
                end
              end
              _updates.push(pkg)
            end
          end
        end

        executor.on_close {
          _logger.info("Collect finished in #{Time.now - _start} seconds.")
          logger.info(node.hostname) { "Collect finished in #{Time.now - _start} seconds. #{_updates.count} updates, #{_blocks.count} blocks. " }
          _logger.info("#{_updates.count} Updates: #{_updates.join(", ")}")
          if _blocks.count > 0
            _logger.info("#{_blocks.count} Blocks: #{_blocks.join(", ")}")
          end
          puts "Finished #{node.hostname} in #{Time.now - _start} seconds."
          if _updates.count > 0
            puts "#{n.hostname} has updates: #{_updates.join(", ")}\n"
            n.updates = _updates.join(",")
            n.blocks = _blocks.join(",")
            n.tstamp = Time.now
            n.save()
          end
        }
      end
    end
  end
end; end
