# Builder

The stemcell builder is a commandline tool to create new stemcells

## Installation

Add this line to your application's Gemfile:

    gem 'stemcell'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install stemcell

## Usage

The following is a listing of commands

    stemcell build SUBCOMMAND ...ARGS  # Build a new stemcell
    stemcell help [TASK]               # Describe available tasks or one specific task
    stemcell info <file>               # Display stemcell information, it looks for stemcell file name <file>

The `stemcell build` command gives the following options

Tasks:
   stemcell build help [COMMAND]  # Describe subcommands or one specific subcommand
   stemcell build noop <name>     # Build a new noop stemcell named <name> [this is good for testing only]
   stemcell build redhat <name>   # Build a new redhat stemcell named <name>
   stemcell build ubuntu <name>   # Build a new ubuntu stemcell named <name>
   stemcell build centos <name>   # Build a new centos stemcell named <name>

Options:
   [--prefix=<prefix>]                  # Directory to use as staging area for all the stemcell work
					# Default: /Users/ankurc/stemcell
   [--architecture=<architecture>]      # Architecture of the OS
					# Default: x86_64
   [--infrastructure=<infrastructure>]  # Infrastructure hosting the vm
					# Default: vsphere
   [--target=<target>]                  # Path for the final stemcell
   [--agent-src-path=<agent_src_path>]  # Bosh Agent Source path
   [--agent-version=<agent version>]    # Bosh Agent Version
					# Default: 0.7.0
   [--bosh-protocol=<bosh_protocol>]    # Bosh Protocol Version
					# Default: 1
   [--iso=<iso file path>]              # Path to the iso file to use
   [--iso-md5=<MD5 of iso file>]        # MD5 of the ISO


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
