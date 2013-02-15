# Builder [![Build Status](https://travis-ci.org/ankurcha/stemcell.png?branch=master)](https://travis-ci.org/ankurcha/stemcell) [![Code Climate](https://codeclimate.com/github/ankurcha/stemcell.png)](https://codeclimate.com/github/ankurcha/stemcell)

The stemcell builder is a commandline tool to create new stemcells

## Installation

Add this line to your application's Gemfile:

    gem 'stemcell'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install stemcell

Install virtualbox
    Follow instructions on: [VirtualBox Download Page](https://www.virtualbox.org/wiki/Downloads)

## Usage

The following is a listing of commands
```
Tasks:
  stemcell build SUBCOMMAND ...ARGS  # Build a new stemcell
  stemcell help [TASK]               # Describe available tasks or one specific task
  stemcell info <file>               # Display stemcell information, it looks for stemcell file name <file>
```
The `stemcell build` command gives the following options

```
Tasks:
  stemcell build centos          # Build a new redhat stemcell
  stemcell build help [COMMAND]  # Describe subcommands or one specific subcommand
  stemcell build noop            # Build a new noop stemcell [this is good for testing only]
  stemcell build redhat          # Build a new redhat stemcell
  stemcell build ubuntu          # Build a new ubuntu stemcell

Options:
  [--name=<name>]                              # Name of the stemcell
  [--prefix=<prefix>]                          # Directory to use as staging area for all the stemcell work
  [--architecture=<architecture>]              # Architecture of the OS
  [--infrastructure=<infrastructure>]          # Infrastructure hosting the vm
  [--target=<target>]                          # Path for the final stemcell
  [--agent-src-path=<agent_src_path>]          # Bosh Agent Source path, this may be the gem or directory path of Bosh agent source
  [--agent-version=<agent_version>]            # Bosh Agent version being installed
  [--agent-protocol=<agent_protocol_version>]  # Bosh Agent Protocol Version being installed
  [--iso=<iso file path>]                      # Path to the iso file to use
  [--iso-md5=<MD5 of iso file>]                # MD5 of the ISO
```

## TODO
This tool is in pre-alpha and supports only a small subset of operations. Currently, the tool is targeted
to be able to create vsphere templates for ubuntu and centOS6. The following is a list of things
that need to be done before we can call it ready for primetime (in order of priority).
* Support AWS
* Support Openstack

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
