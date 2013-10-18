# Rubdian

rubdian is a tool to automatically collect available updates on debian based systems.

It can blacklist certain packages to prevent unwanted behaviour.  (e.g. unattended restart of a database)

## Important informations

rubdian is currently in **alpha** state. This means it might do something not as expected and in the worst case cause serious problems if upgrading an actual blacklisted item due to a bug in the blacklist command.

rubdian is being developed in an environment with a hundreds of servers so we actually take care to not break things. Before we use the rubdian development branch (master) on our own, we test it in a simulated environment of a few servers. This does **not** mean that you can expect a working copy in this repository since we don't use any unit tests at all in the moment meaning there is a lot of room for bugs.

The rubdian gem is currently only available in our own network and not yet pushed to rubygems.org or something. If you already want to test rubdian, you have to build it from source which makes it even more dangerous to use.

We plan to release rubdian to rubygems.org in version 0.1.0, being the first stable one. There is currently the lack of right error handling and some features we want to have are not even implemented yet.

Nevertheless, if you really want to use rubdian by now, we'd appreciate it if you'd drop us a comment on dev+rubdian@corpex.de or open an issue on github. You can also (and we'd love it) fork this repo and start hacking with us.

Please do not contact us if you need support in using rubdian directly.

## Installation

rubdian needs at least ruby 1.9 and the sqlite3 development headers to build the sqlite3 gem.

To install rubdian run:

        $ gem install rubdian

rubdian will print a post installation message. **It might be worth to read it.**

## Install from source

To install rubdian (e.g. the latest development version) from source, clone this repository first:

        $ git clone https://gitlab.corpex-net.de/corpex/rubdian.git

Change into the newly created directory

        $ cd rubdian

Install rubdian's dependencies

        $ bundle install

If you don't have bundle installed, install it by

        $ gem install bundler

or as root

        $ sudo gem install bundler

Now build and install the gem from source

        $ rake install

## Updating

To get the latest stable version of rubdian update it with the gem command

        $ gem update rubdian

Please ensure to backup your configuration before you upgrade. It is best to backup the whole rubdian homedirectory, except logs. After you did the update for rubdian, rerun

        $ rubdian setup

## Configuration

rubdian uses a YAML file for its configuration parameters. Everytime you upgrade rubdian, you should run

        $ rubdian setup

This will overwrite rubdian.yml in $RUBDIAN\_HOME. Never edit rubdian.yml directly. If you want to make custom changes, create a file called *rubdian.local.yml* in $RUBDIAN\_HOME and simply overwrite the changes there. If you, for example, want to overwrite the command to collect the updates, you would do:

        $ vi $RUBDIAN_HOME/rubdian.local.yml

and add

        rubdian:
                commands:
                        collect: yournewcommand && apt-get upgrade -s

This will prevent the loss of your custom made changes after a rubdian upgrade.

For a full explanation of every configuration parameter see *$RUBDIAN\_HOME/rubdian.yml.dist* for more details.

## Usage

Usage: rubdian [options] subdcommand [options] [arg ... arg]

See

        $ rubdian --help

### Setup

You need to setup an initial rubdian config and home directory. This can be done by running rubdian's setup subcommand.

        $ rubdian setup

Or, if you want to install it to a different location

        $ rubdian setup -l /usr/local/etc/rubdian

Setup will generate a rubdian.yml configuration file without any comments in it. See *$RUBDIAN\_HOME/rubdian.yml.dist* for more informations.

### Rubdian Database

rubdian uses a database to store informations about the collected updates, blacklist, etc.

By default it is using a sqlite3 database located at *$RUBDIAN\_HOME/rubdian.db*.  The database is automatically being created when rubdian starts for the first time.

rubdian is using Sequel (http://sequel.rubyforge.org/) for its database communication and thus it supports all kind of databases supported by Sequel.

To configure a different database change the database connection uri in *$RUBDIAN\_HOME/rubdian.local.yml* as described in *$RUBDIAN\_HOME/rubdian.yml.dist*.

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

One can say 10 is a good value. **!!!!NO WARRANTY!!!!**

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

To queue all hosts that have a certain package in their update list type

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
