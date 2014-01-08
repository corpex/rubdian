require "cpx/distexec"
require "cpx/distexec/executor/ssh"
require "rubdian"
require "logger"
require "rubdian/database"
require "rubdian/trollop"

module Rubdian; module Command
  module Collect
    def self.main(opts = {})
      history = Rubdian::Database::History.new
      history.begin = Time.now
      history.action = "collect"
      history.message = "collecting updates"
      history.username = opts[:username]
      history.options = opts.to_s

      logger = Rubdian.logger
      cfg = Rubdian.config

      lopts = Trollop::options do
        banner "Collect updates"
        opt :filter, "Set filter in format key=value. Backend must support filtering. Can be used multiple times.", :short => "-F", :type => String, :multi => true
        opt :list_hosts, "Show hosts without collecting and exit.", :short => '-l', :default => false
      end

#      require cfg['rubdian']['distexec']['backend']['require']
#      _beclass = eval(cfg['rubdian']['distexec']['backend']['driver']) # dirty
      Cpx::Distexec.logger.level = Rubdian.logger.level
#      if ! File.exists?(opts[:source])
#        $stderr.puts "source file #{opts[:source]} not found."
#        exit 1
#      end

      _bopts = { :file => opts[:source] }

      _bopts.update(:filter => lopts[:filter] ) if ! lopts[:filter].nil?
      logger.debug("Backend options: #{_bopts.inspect}")
      if File.exists?(opts[:source]) and cfg['rubdian']['distexec']['backend']['driver'] == 'Cpx::Distexec::Backend::FileBackend' # very, VERY dirty..
        _be = opts[:source]
      else
        _be = cfg['rubdian']['distexec']['backend']['driver']
      end
      Cpx::Distexec.set_backend(_be, _bopts)
      Cpx::Distexec.set_executor(Cpx::Distexec::Executor::SSH, :username => opts[:username], :timeout => 4, :user_known_hosts_file => '/dev/null')
      logger.info("collect") { "Loading nodes from #{cfg['rubdian']['distexec']['backend']['driver']}" }
      nodes = Cpx::Distexec.load_nodes
      logger.info("collect") { "#{nodes.count} nodes loaded." }

      _blacklist = Rubdian::Database::Blacklist.filter()
      blacklist = []
      _blacklist.each do |b|
        blacklist << b.package
      end

      if lopts[:list_hosts]
        logger.debug("Show server list only")
        _nodes = Cpx::Distexec.load_nodes
        _nodes.each do |n|
          puts n.hostname
        end
        exit 0
      end

      logger.debug("Using #{cfg['rubdian']['commands']['collect']} to collect updates...")
      counter = 0
      collected = []
      processed = []
      tooks = 0
      puts "Processing #{nodes.count} nodes... this may take a while."
      start = Time.now
      Cpx::Distexec.exec(cfg['rubdian']['commands']['collect'], :concurrent => opts[:concurrent], :execution_timeout => 160, :trap => true, :trap_message => "Waiting for remaining nodes.") do |node, executor|
        _history = Rubdian::Database::History.new
        _history.begin = Time.now
        _history.action = "collect"
        _history.username = opts[:username]
        _history.options = opts.to_s
        processed << node
        counter += 1
        _logger = nil
        if opts[:log_split]
          _log = "#{Rubdian.default[:logdir]}/#{node.hostname}.log"
          _logger = Logger.new(_log)
          _logger.level = Rubdian.logger.level
        else
          _logger = Rubdian.logger
        end

        _hl = "-" * 80
        _start = Time.now
        _logger.info(node.hostname) { _hl }
        _logger.info(node.hostname) { "[#{counter}/#{nodes.count}] Starting collect on #{Time.now}" }
        _logger.info(node.hostname) { "Using command: #{cfg['rubdian']['commands']['collect']}" }

        n = Rubdian::Database::Node.filter(:hostname => node.hostname).first()
        if n.nil?
          n = Rubdian::Database::Node.new
          n.hostname = node.hostname
          if ! node.port.nil?
            n.port = node.port
          end
        end
        n.updates = ""
        n.blocks = ""
        n.blocked = false
        _retried = false
        begin
          n.save
        rescue
          # db may be locked due to -i dont know yet-, simply retry.
          raise if _retried
          _retried = true
          retry
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
              _logger.info(node.hostname) { "Update #{pkg}: #{_curVersion} to #{_newVersion}" }
              _blocked = false
              blacklist.each do |b|
                _logger.debug(node.hostname) { "Comparing #{pkg} with #{b}..." }
                if pkg.match(b)
                  _logger.warn(node.hostname) { "Blocking #{pkg} (#{b})" }
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
          _took = Time.now - _start
          tooks += _took
          _logger.info(node.hostname) { "Collect finished in #{_took} seconds." }
          _logger.info(node.hostname) { "#{_updates.count} Updates: #{_updates.join(", ")}" }
          if _blocks.count > 0
            _logger.info(node.hostname) { "#{_blocks.count} Blocks: #{_blocks.join(", ")}" }
          end
          _ups = _updates.count
          _blks = _blocks.count
          if _updates.count > 0
            n.updates = _updates.join(",")
            n.blocks = _blocks.join(",")
            n.tstamp = Time.now
            n.save()
            collected << n
            if _blks > 0
              _blks = _blks.to_s.red
              _ups = _ups.to_s.yellow
            else
              _ups = _ups.to_s.green
            end
          end

          _msg = "#{node.hostname}, #{_ups} updates and #{_blks} blocks found."
          _history.message = _msg
          _history.end = Time.now
          _history.save
          puts _msg
        }
      end
      puts "#{processed.count} processed, #{collected.count} with updates."
      _took = Time.now - start
      _seconds = _took % 60
      _mins = _took / 60
      _hours = _mins / 60
      _mins = _mins % 60
      _avg = tooks / processed.count
      logger.info("Total time: #{_took} seconds.")
      history.end = Time.now
      history.save
      printf("Total time: %i Hours, %i Minutes and %i Seconds with an average of %f seconds per host.\n", _hours, _mins, _seconds, _avg)
    end
  end
end; end
