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
      Cpx::Distexec.set_backend(_beclass, :file => opts[:list])
      Cpx::Distexec.set_executor(Cpx::Distexec::Executor::SSH, :username => opts[:username], :timeout => 4, :user_known_hosts_file => '/dev/null')

      Cpx::Distexec.load_nodes


      blacklist = Rubdian::Database::Blacklist.filter()
      logger.debug("Using #{cfg['rubdian']['commands']['collect']} to collect updates...")
      Cpx::Distexec.exec(cfg['rubdian']['commands']['collect'], :concurrent => opts[:concurrent], :execution_timeout => 160) do |node, executor|
        n = Rubdian::Database::Node.filter(:hostname => node.hostname).first()
        if n.nil?
          n = Rubdian::Database::Node.new
          n.hostname = node.hostname
        end
        _blocks = []
        _updates = []
        logger.debug("Running on #{node.hostname}")
        executor.on_data do |data, type|
          # grabbing install data
          data = data.chomp
          data = data.lstrip
          data = data.rstrip
          s = data.split("\n")
          s.each do |data|
            if data =~/^Inst/
              spl = data.split(" ", 3)
              pkg = spl[1]
              _spl = spl[2].split(" ", 3)
              _curVersion = _spl[0]
              _newVersion = _spl[1]
              _curVersion = _curVersion.delete "["
              _curVersion = _curVersion.delete "]"
              _newVersion = _newVersion.delete "("
              logger.debug("#{pkg}: #{_curVersion} to #{_newVersion}")
              _blocked = false
              blacklist.each do |b|
                logger.debug("Comparing #{pkg} with #{b[:package]}...")
                if pkg.match(b[:package])
                  logger.debug("Blacklisting #{node.hostname}, blocking #{pkg} (#{b[:package]})")
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
          logger.debug("Finished #{node.hostname}, saving.")
          n.updates = _updates.join(",")
          n.blocks = _blocks.join(",")
          n.tstamp = Time.now
          n.save()
        }
      end
    end
  end
end; end
