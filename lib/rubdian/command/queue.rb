require "rubdian"
require "rubdian/database"

module Rubdian; module Command
  module Queue

    def self.main(opts = {})
      logger = Rubdian.logger
      lopts = Trollop::options do
        banner <<-EOF
Usage:
  rubdian queue [options] hostlist

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
        opt :short, "Just print the servernames when using -l", :short => "-s"
        opt :apply_blacklist, "Apply current blacklist", :short => "-b"
        conflicts :list_queued, :list_unqueued
      end

      if lopts[:apply_blacklist]
        nodes = Rubdian::Database::Node.filter
        blacklist = Rubdian::Database::Blacklist.filter
        nodes.each do |node|
          _blocks = []
          _ups = node.updates.split(",")
          _ups.each do |u|
            blacklist.each do |b|
              if u.match(b.package)
                _blocks << u
              end
            end
          end
          node.blocks = _blocks.join(",")
          node.save
        end
        exit 0
      end

      if lopts[:list]
        filter = {}

        if lopts[:list_queued]
          filter.update({ :queued => 1 })
        end

        if lopts[:list_unqueued]
          filter.update({ :queued => false })
        end

        nodes = Rubdian::Database::Node.filter(filter)
        nodes = self.filter_nodes(nodes, ARGV) if ARGV.count > 0
        nodes.each do |node|
          next if node.updates.nil? or node.updates.empty?

          if lopts[:match].count > 0
            next if ! self.match!(node.updates.split(","), lopts[:match])
          end
          if ! lopts[:short]
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
          else
            printf("%s\n", node.hostname)
          end
        end
      end

      if lopts[:delete]
        nodes = Rubdian::Database::Node.filter(:queued => 1)
        nodes = self.filter_nodes(nodes, ARGV) if ARGV.count > 0
        nodes.each do |node|
          if lopts[:match].count > 0
            _matched = self.match!(node.updates.split(","), lopts[:match])
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
      end


      if lopts[:add]
        nodes = Rubdian::Database::Node.filter
        nodes = self.filter_nodes(nodes, ARGV) if ARGV.count > 0
        nodes.each do |node|
          next if node.updates.nil? or node.updates.empty?
          if node.queued
            logger.debug("QUEUE:add") { "Skipping #{node.hostname}, already queued." }
            next
          end
          if ! node.blocks.empty? and ! lopts[:force]
            logger.warn("QUEUE:add") { "Skipping #{node.hostname} due to blocks. (#{node.blocks})" }
            next
          end

          if lopts[:match].count > 0
            _matched = self.match!(node.updates.split(","), lopts[:match])
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
      end
    end


    def self.match(search, array, &blocks)
      _matches = []
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

    def self.filter_nodes(nodes, array, &blocks)
      _result = []
      nodes.each do |node|
        array.each do |search|
          if search.match(/^\//)
            # expect regex. regex has to end with /
            next if ! search.match(/\/$/)
            search = search.delete "/"
            if node.hostname.match(search)
              _result << node
              yield(node, search) if block_given?
              next
            end
          else
            # expect full hostname
            if node.hostname == search
              _result << node
              yield(node, search) if block_given?
              next
            end
          end
        end
      end
      return _result
    end
  end
end; end
