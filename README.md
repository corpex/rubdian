# Rubdian

rubdian is a tool to automatically collect available updates on debian based systems.

It can blacklist certain packages to prevent unwanted behaviour.  (e.g. unattended restart of a database)

## Installation

rubdian needs at least ruby 1.9 and the sqlite3 development headers to build the sqlite3 gem.

To install rubdian run:

    $ gem install rubdian

rubdian will print a post installation message. **It might be worth to read it.**

## Usage

Usage: rubdian [options] subdcommand [options] [arg ... arg]

See

        $ rubdian --help

### Setup

You need to setup an initial rubdian config and home directory. This can be done by running rubdian's setup subcommand.

        $ rubdian setup

Or, if you want to install it to a different location

        $ rubdian setup -l /usr/local/etc/rubdian

Setup will generated a rubdian.yml configuration file without any comments in it. See *$RUBDIAN\_HOME/rubdian.yml.dist* for more informations.

### Rubdian Database

rubdian uses a database to store informations about the collected updates, blacklist, etc.

By default it is using a sqlite3 database (*$RUBDIAN\_HOME/rubdian.db*).  The database is automatically being created when rubdian starts for the first time.

rubdian is using Sequel (http://sequel.rubyforge.org/) for its database communication and thus it supports all kind of databases supported by Sequel.

To configure a different database change the database connection uri in *$RUBDIAN\_HOME/rubdian.yml*.

### server.list

By now, rubdian only supports plain text files as it's input source for hostnames to perform its operations on. The layout of such a file is very simple as it's basically just a newline seperated list of hostnames.

        server.domain.tld
        server2.domain.tld
        server3.domain.tld

You can also provide a different ssh port by separating it with a colon

        server.domain.tld
        server2.domain.tld:2222
        server4.domain.tld

This, of course, breaks plain IPv6 addresses.

rubdian looks by default for a file named **server.list** in it's home directory. You can also provide a different source:

        $ rubdian -s /path/to/my/source

### Authentication

rubdian is using SSH for its connections to the servers.

It uses either $USER, $SUDO\_USER or $RUBDIAN\_USER as its default username to connect. You can change this with:

        $ rubdian -u yourusername

By default, rubdian expects to authenticate over ssh with key based authentication (which is recommended). If you're using a password for your connection you can let rubdian ask you once for it to use it onwards. This assumes that you're using the same password on every host rubdian performs on.

        $ rubdian -u yourusername -p

Yo **can not** provide a password with -p on the commandline as it will show up in *ps aux*, *top* or other taskmanager. rubdian will interpret your password as a subcommand and exit with a failure. **It might also write it into its logfile!**


### Blacklist

Sometimes you don't want to upgrade certain packages and sometimes you're just too lazy to set them on hold. If so, rubdian's blacklist is your friend.

The blacklist is based on regex pattern so by blacklisting *apache* you'll blacklist every package that contains apache in its name.

To add a regex to the blacklist type

        $ rubdian blacklist -a apache           # all packages with apache in their name
        $ rubdian blacklist -a '^apache'        # all packages starting with apache
        $ rubdian blacklist -a '^apache2$'      # blacklist the exact name of the package

To delete a regex type

        $ rubdian blacklist -d '^apache'

To list all type

        $ rubdian blacklist -l


### Collecting Updates

Now that the authentication mechanism and server.list are explained, let's start collecting the updates by typing

        $ rubdian [options] collect

rubdian can collect on multiple hosts in the same time.

        $ rubdian [options] -c 10 collect

Will start 10 simultaneously threads.

**Attention:** It is not recommended to use a count higher than 10, especially not on virtualized systems.

One can say 10 is a good value. (**!!!!NO WARRANTY!!!!**)

### Queueing Hosts

You have to queue the hosts you want to update.

#### List all hosts

rubdian has a nice output to let you see all collected hosts along with their updates. It also shows you in different colors either if the host is already queued or if it has blocking packages.

        $ rubdian queue -l

#### Adding a host to queue

To queue all hosts without blocking (blacklisted) packages type

        $ rubdian queue -a

To queue certain hosts type

        $ rubdian queue -a server.domain.tld server3.domain.tld

To queue all hosts that have certain package in their update list type

        $ rubdian queue -a -m apache2

This will add all hosts with updates containing the string 'apache2' in their name to the queue.

*-m* uses regex to match the package so if you want to specify the exact package name you would do

        $ rubdian queue -a -m '^apache2$'

If a package is blocking, you can use *-f* to force adding it to queue.

#### Removing a host from queue

To remove all hosts from queue type

        $ rubdian queue -d

To remove certain hosts from queue type

        $ rubdian queue -d server3.domain.tld server2.domain.tld

You can also use the *-m* flag as in adding a host.

### Perform the upgrade

To upgrade the packages type

        $ rubdian [options] upgrade

You can also use *-c* for the upgrade. As already mentioned above a higher count as 10 is **NOT** recommended! Use *-c* at your own risk!

## Troubleshooting

Please report bugs to the gitlab issue system we're using.

rubdian is writing for most of its operations logfiles to $RUBDIAN\_HOME/logs/

You can also enable debug messages that will be written to logfiles by providing
the *-d* flag.

You can also send an email to bugs+rubdian@corpex.de or yell at me, if you're around.

## Donations

If you think rubdian improved your life drop me some nuts.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
