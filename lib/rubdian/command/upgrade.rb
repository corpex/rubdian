require "rubdian"
require "rubdian/database"
require "cpx/distexec"
require "cpx/distexec/executor/ssh"
require "cpx/distexec/node"
require "resolv"
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
        begin
          n = Cpx::Distexec::Node.new
          n.hostname = node.hostname
          n.ipaddress = Resolv.getaddress(node.hostname)
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

      Cpx::Distexec.exec(Rubdian.config['rubdian']['commands']['upgrade'], :concurrent => opts[:concurrent], :execution_timeout => 3600, :nodes => nodes) do |node, executor|
        _log = "#{Rubdian.default[:logdir]}/#{node.hostname}.log"
        logger.debug("Upgrading #{node.hostname}, logging to #{_log}")
        _logger = Logger.new(_log)
        _logger.level = Rubdian.logger.level
        puts "Starting upgrade on #{node.hostname}"
        _hl = "-" * 80
        _start = Time.now
        _logger.info(_hl)
        _logger.info("Starting upgrade on #{Time.now}")
        _logger.info("Upgrading following packages:")
        _logger.info(node.data.updates.split(",").join(", "))

        executor.on_data do |data, type|
          case type
            when 0
              _logger.info(type) { data.chomp }
            else
              _logger.error(type) { data.chomp }
          end
        end

        executor.on_close {
          puts "Upgrade on #{node.hostname} finished in #{Time.now - _start} seconds."
          _logger.info("Upgrade finished. Took: #{Time.now - _start} seconds.")
          node.data.delete # remove node from database. the actual node is stored in data of the distexec node object. weird, I know.
        }
      end

    end
  end
end; end
