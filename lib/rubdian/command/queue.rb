require "rubdian"
require "rubdian/database"

module Rubdian; module Command
  module Queue

    def self.main(opts = {})
      logger = Rubdian.logger
      lopts = Trollop::options do
        banner <<-EOF
Usage:
  rubdian [options] hostlist

Usage examples:

    # queue all hosts
    rubdian queue -a

    # queue all hosts, even blocked ones
    rubdian queue -f -a

    # remove all hosts from queue
    rubdian queue -d

    # queue certain hosts
    rubdian queue -a host1 host2 host3

    # queue certain hosts, even if blocked
    rubdian queue -f -a host1 host2 host3

    # remove certain hosts from queue
    rubdian queue -d host1 host2 host3

    # add all hosts to queue with 'vim' in their update list.
    rudian queue -a -m vim

    # add all hosts to queue with 'vim' and 'irssi' in their update list.
    rubdian queue -a -m vim -m irssi

    # remove all hosts from queue that want to update mysql.
    rubdian queue -d -m '^mysql'

EOF
        banner ""
        opt :force, "Force operation (i.e. ignore blocks)", :short => "-f"
        opt :add, "Add certain hosts (or all if hostlist is omitted) to queue", :short => "-a"
        opt :delete, "Delete certain hosts (or all if hostlist is omitted) from queue", :short => "-d"
        opt :match, "If used with -a, only hosts with updates matching this parameter will be added to queue. If used with -d, hosts with updates matching this parameter will be deleted from queue. can be a regular expression", :short => "-m", :multi => true, :type => String
        opt :list, "List all nodes", :short => "-l"
        opt :list_queued, "List queued nodes", :short => "-q"
        opt :list_unqueued, "List unqueued nodes", :short => "-n"
      end

      if lopts[:list]
        filter = {}

        if lopts[:list_queued]
          filter.update({ :queued => 1 })
        end

        if lopts[:list_unqueued]
          filter.update({ :queued => false })
        end
        all = Rubdian::Database::Node.filter(filter)
        all.each do |node|
          if lopts[:match].count > 0
            _ups = node.updates.split(",")
            _matched = false
            _ups.each do |up|
              lopts[:match].each do |rx|
                if up.match(rx)
                  _matched = true
                  break
                end
              end
            end
            if ! _matched
              next
            end
          end
          _queued = " "
          _queued = "*".green if node.queued
          _queued = "!".red if ! node.blocks.empty?
          _queued = "#".yellow if ! node.blocks.empty? and node.queued
          _blocks = node.blocks.split(",")
          _updates = node.updates.split(",")
          _pu = []
          _updates.each do |u|
            if _blocks.include? u
              _pu << "#{u}".red
            else
              _pu << u
            end
          end
          printf("  %s %-40s %-16s\n", _queued, node.hostname, _pu.join(", "))
        end
      end

      if lopts[:delete]
        if ARGV.count == 0
          # remove all from queue
          all = Rubdian::Database::Node.filter(:queued => 1)
          all.each do |node|
            if lopts[:match].count > 0
              _ups = node.updates.split(",")
              _matched = false
              _ups.each do |up|
                lopts[:match].each do |rx|
                  if up.match(rx)
                    _matched = true
                    break
                  end
                end
              end
              if ! _matched
                logger.debug("QUEUE:delete") { "Skipping #{node.hostname}, updates do not match any of #{lopts[:match]}" }
                next
              end
            end
            logger.debug("QUEUE:delete") { "Removing #{node.hostname} from queue." }
            node.queued = false
            node.save
          end
          exit 0
        else
          # remove certain hosts from queue
          ARGV.each do |h|
            node = Rubdian::Database::Node.filter(:hostname => h).first()
            if node.nil?
              logger.error("QUEUE:delete") { "Can not remove #{h} from queue: not found in database." }
              next
            end
            if lopts[:match].count > 0
              _ups = node.updates.split(",")
              _matched = false
              _ups.each do |up|
                lopts[:match].each do |rx|
                  if up.match(rx)
                    _matched = true
                    break
                  end
                end
              end
              if ! _matched
                logger.debug("QUEUE:delete") { "Skipping #{node.hostname}, updates do not match any of #{lopts[:match]}" }
                next
              end
            end
            node.queued = false
            node.save
          end
          exit 0
        end
      end


      if lopts[:add]
        if ARGV.count == 0
          # queue all hosts.
          all = Rubdian::Database::Node.filter
          all.each do |node|
            if node.queued
              logger.debug("QUEUE:add") { "Skipping #{node.hostname}, already queued." }
              next
            end
            if ! node.blocks.empty? and ! lopts[:force]
              logger.warn("QUEUE:add") { "Skipping #{node.hostname} due to blocks. (#{node.blocks})" }
              next
            end

            if lopts[:match].count > 0
              _ups = node.updates.split(",")
              _matched = false
              _ups.each do |up|
                lopts[:match].each do |rx|
                  if up.match(rx)
                    _matched = true
                    break
                  end
                end
              end
              if ! _matched
                logger.debug("QUEUE:add") { "Skipping #{node.hostname}, updates do not match any of #{lopts[:match]}" }
                next
              end
            end
            logger.info("QUEUE:add") { "Adding #{node.hostname} to queue. #{node.updates.split(",").count} updates, #{node.blocks.split(",").count} blocks" }
            puts "Adding #{node.hostname} to queue (#{node.updates})\n"
            node.queued = true
            node.save
          end
          queued = Rubdian::Database::Node.filter(:queued => 1)
          logger.info("QUEUE:add") { "Queued #{queued.count} hosts." }
          puts "Queued #{queued.count} hosts.\n"
          exit 0
        else
          # queue certain hosts
          ARGV.each do |h|
            node = Rubdian::Database::Node.filter(:hostname => h).first()
            if node.nil?
              logger.warn("QUEUE:add") { "Can not queue #{h}: not found in database." }
              next
            end
            if ! node.blocks.empty? and ! lopts[:force]
              logger.warn("QUEUE:add") { "Skipping #{node.hostname} due to blocks. (#{node.blocks})" }
              next
            end

            if lopts[:match].count > 0
              _ups = node.updates.split(",")
              _matched = false
              _ups.each do |up|
                lopts[:match].each do |rx|
                  if up.match(rx)
                    _matched = true
                    break
                  end
                end
              end
              if ! _matched
                logger.debug("Skipping #{node.hostname}, updates do not match any of #{lopts[:match]}")
                next
              end
            end
            puts "Adding #{node.hostname} to queue\t(#{node.updates})\n"
            logger.info("QUEUE:add") { "Adding #{node.hostname} to queue. #{node.updates.split(",").count} updates, #{node.blocks.split(",").count} blocks" }
            node.queued = true
            node.save()
          end
          exit 0
        end
      end
    end

    def self.match(search, array, &blocks)
      _matches = []
      puts search.class
      search = search.split() if search.class == String
      search.each do |string|
        array.each do |elem|
          if string.match(elem)
            _matches << elem
            yield(string, elem) if block_given?
          end
        end
      end
      _matches = nil if _matches.count == 0
      return _matches
    end
    def self.match!(search, array, &blocks)
      self.match(search, array) do |str, matched|
        yield(str, matched) if block_given?
        return matched
      end
      return nil
    end
  end
end; end
