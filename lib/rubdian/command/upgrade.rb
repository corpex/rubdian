require "rubdian"
require "rubdian/database"
require "cpx/distexec"
require "cpx/distexec/executor/ssh"
require "cpx/distexec/node"
require "resolv"

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
        logger.debug("Upgrading #{node.hostname}")
        executor.on_data do |data, type|
          puts "#{data.chomp}\n"
        end

        executor.on_close {
          puts "#{node.hostname} finished."
          node.data.delete # remove node from database. the actual node is stored in data of the distexec node object. weird, I know.
        }
      end

    end
  end
end; end
