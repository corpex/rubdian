require "rubdian"
require "rubdian/database"
require "cpx/distexec"
require "cpx/distexec/executor/ssh"
require "cpx/distexec/node"
require "logger"

module Rubdian; module Command
  module Upgrade
    def self.main(opts = {})
      logger = Rubdian.logger
      Cpx::Distexec.logger.level = logger.level
      lopts = Trollop::options do
      end

      all = Rubdian::Database::Node.filter(:queued => 1)
      nodes = []
      all.each do |node|
        logger.debug("Loading #{node.hostname} from queue.")
        begin
          n = Cpx::Distexec::Node.new
          n.hostname = node.hostname
          if ! node.port.nil?
            n.port = node.port
          end
          n.data = node
          nodes << n
        rescue Exception, e
          logger.error("Error while converting to distexec node: #{e.message}")
        end
      end
      Cpx::Distexec.set_executor(Cpx::Distexec::Executor::SSH, :username => opts[:username], :timeout => 10, :user_known_hosts_file => '/dev/null')
      counter = 0
      processed = []
      puts "Processing #{nodes.count} nodes... this may take a while"
      start = Time.now
      tooks = 0
      Cpx::Distexec.exec(Rubdian.config['rubdian']['commands']['upgrade'], :concurrent => opts[:concurrent], :execution_timeout => 3600, :nodes => nodes, :trap => true) do |node, executor|
        _logger = nil
        if opts[:log_split]
          _log = "#{Rubdian.default[:logdir]}/#{node.hostname}.log"
          _logger = Logger.new(_log)
          _logger.level = Rubdian.logger.level
        else
          _logger = Rubdian.logger
        end
        puts "Starting upgrade on #{node.hostname}"
        _hl = "-" * 80
        _start = Time.now
        _logger.info(node.hostname) { _hl }
        _logger.info(node.hostname) { "Starting upgrade on #{Time.now}" }
        _logger.info(node.hostname) { "Using command: #{Rubdian.config['rubdian']['commands']['upgrade']}" }
        _logger.info(node.hostname) { "Upgrading following packages: #{node.data.updates}" }

        executor.on_data do |data, type|
          case type
            when 0
              _logger.info(node.hostname) { "#{type}: #{data.chomp}" }
            else
              _logger.error(node.hostname) { "#{type}: #{data.chomp}" }
          end
        end

        executor.on_close {
          _took = Time.now - _start
          tooks += _took
#          puts "Upgrade on #{node.hostname} finished in #{_took.round(1)} seconds."
          _logger.info(node.hostname) { "Upgrade finished. Took: #{_took} seconds." }
          processed << node
          node.data.updates = nil
          node.data.blocks = nil
          node.data.queued = false
          node.data.blocked = false
        }
      end
      puts "#{processed.count} processed."
      _took = Time.now - start
      _seconds = _took % 60
      _mins = _took / 60
      _hours = _mins / 60
      _mins = _mins % 60
      _avg = tooks / processed.count
      logger.info("Total time: #{_took} seconds.")
      printf("Total time: %i Hours, %i Minutes and %i Seconds with an average of %f seconds per host.\n", _hours, _mins, _seconds, _avg)
    end
  end
end; end
