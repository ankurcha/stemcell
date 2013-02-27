require 'logger/colors'
require 'veewee'
require 'deep_merge'
require 'erb'
require 'securerandom'
require 'digest/sha1'

module Bosh::Agent::StemCell

  # This BaseBuilder abstract class represents the base stemcell builder and should be extended by specific stemcell
  # builders for different distributions
  class BaseBuilder

    attr_accessor :name, :infrastructure, :architecture
    attr_accessor :agent_src_path, :agent_version, :bosh_protocol
    attr_accessor :prefix, :target
    attr_accessor :iso, :iso_md5, :iso_filename
    attr_accessor :logger
    attr_accessor :vm_name

    # Stemcell builders are initialized with a manifest and a set of options. The options provided are merged with the
    # defaults to allow the end user/developer to specify only the ones that they wish to change and fallback to the defaults.
    #
    # The stemcell builder options are as follows
    #{
    #  :name => 'bosh-stemcell', # Name of the output stemcell
    #  :logger => Logger.new(STDOUT), # The logger instance to use
    #  :target => "bosh-#@type-#@agent_version.tgz", # Target file to generate, by default it will the ./bosh-#@type-#@agent_version.tgz
    #  :infrastructure => 'vsphere', # The target infrastructure, this can be aws||vsphere||openstack
    #  :agent_src_path => './bosh_agent-0.7.0.gem', # The path to the stemcell gem to be installed
    #  :agent_version => '0.7.0', # Agent version
    #  :bosh_protocol => '1', # Bosh protocol version
    #  :architecture => 'x86_64', # The target system architecture
    #  :prefix => `pwd`, # Directory to use as the staging area and where the stemcell will be generated
    #  :iso => nil, # The url from where the builder can download the stemcell
    #  :iso_md5 => nil, # The MD5 hash of the iso
    #  :iso_filename => nil # Optional iso filename to use/search for in the iso folder
    #}
    #
    # The stemcell manifest is as follows
    #{
    # :name => @name, # the bosh stemcell name given as a part of the options[:name]
    # :version => @agent_version, # The agent version
    # :bosh_protocol => @bosh_protocol,
    # :cloud_properties => {
    #    :infrastructure => @infrastructure,
    #    :architecture => @architecture
    #    :root_device_name => '/dev/sda1'
    #  }
    #}
    def initialize(opts)
      @logger = opts[:logger] || Logger.new(STDOUT)
      @logger.level = Logger.const_get(opts[:log_level] || "INFO")
      @name = opts[:name] || Bosh::Agent::StemCell::DEFAULT_STEMCELL_NAME
      @vm_name = opts[:name] || SecureRandom.uuid.gsub(/-/,'')
      @prefix = File.expand_path(opts[:prefix] || Dir.pwd)
      @infrastructure = opts[:infrastructure] || Bosh::Agent::StemCell::DEFAULT_INFRASTRUCTURE
      @architecture = opts[:architecture] || Bosh::Agent::StemCell::DEFAULT_ARCHITECTURE
      @agent_version = opts[:agent_version] || Bosh::Agent::VERSION
      @bosh_protocol = opts[:agent_protocol] || Bosh::Agent::BOSH_PROTOCOL
      @agent_src_path = File.expand_path(opts[:agent_src_path] || "./bosh_agent-#{@agent_version}.gem")
      @target ||= File.join(@prefix, "#@name-#{type}-#@infrastructure-#{@agent_version}.tgz")
      @iso = opts[:iso]
      @iso_md5 = opts[:iso_md5]
      @gui = opts[:gui]
      @definitions_dir = opts[:definitions_dir]
      @stemcell_files = [] # List of files to be packaged into the stemcell

      if @iso
        unless @iso_md5
          raise "MD5 must be specified is ISO is specified"
        end
        @iso_filename ||= File.basename @iso
      else
        init_default_iso
      end

      sanity_check
    end

    # This method does the setup, this implementation takes care of copying over the
    # correct definition files, packaging the agent and doing any related setup if needed
    def setup
      copy_definitions
      package_agent
    end

    # This method creates the vm using the #@name as the virtual machine name
    # If an existing VM exists with the same name, it will be deleted.
    def build_vm
      Dir.chdir(@prefix) do
        @logger.info "Building vm #@name"
        nogui_str = gui? ? "" : "--nogui"

        execute_veewee_cmd "build '#@vm_name' --force --auto #{nogui_str}", {:on_error => "Unable to build vm #@name"}

        # execute pre-shutdown hook
        pre_shutdown_hook

        @logger.info "Export built VM #@name to #@prefix"
        sh "vagrant basebox export '#@vm_name' --force", {:on_error => "Unable to export VM #@name: vagrant basebox export '#@vm_name'"}

        @logger.debug "Sending veewee destroy for #@name"
        execute_veewee_cmd "destroy '#@vm_name' --force #{nogui_str}"
      end

    end

    def pre_shutdown_hook
      # nothing
    end

    def type
      raise NotImplementedError.new("Type must be initialized")
    end

    def init_default_iso
      raise NotImplementedError.new("Default ISO options must be provided")
    end

    # Packages the stemcell contents (defined as the array of file path argument)
    def package_stemcell
      @stemcell_files << generate_image << generate_manifest << stemcell_files
      # package up files
      package_files
    end

    def generate_manifest
      stemcell_mf_path = File.expand_path "stemcell.MF", @prefix
      File.open(stemcell_mf_path, "w") do |f|
        f.write(manifest.to_yaml)
      end
      stemcell_mf_path
    end

    def generate_image
      image_path = File.join @prefix, "image"
      Dir.chdir(@prefix) do
        sh("tar -xzf #@vm_name.box > /dev/null 2>&1", {:on_error => "Unable to unpack .box file"})
        Dir.glob("*.ovf") { |ovf_file| fix_virtualbox_ovf ovf_file } # Fix ovf files
        sh("tar -czf #{image_path} *.vmdk *.ovf > /dev/null 2>&1", {:on_error=>"Unable to create image file from ovf and vmdk"})
        FileUtils.rm [Dir.glob('*.box'), Dir.glob('*.vmdk'), Dir.glob('*.ovf'), "Vagrantfile"]
        @image_sha1 = Digest::SHA1.file(image_path).hexdigest
      end
      image_path
    end

    def stemcell_files
      # No extra stemcell files
    end

    # Main execution method that sets up the directory, builds the VM and packages everything into a stemcell
    def run
      setup
      build_vm
      package_stemcell
      cleanup
      @target
    end

    def cleanup
      @logger.info "Cleaning up files: #@stemcell_files"
      FileUtils.rm_rf @stemcell_files
    end

    def manifest
      @manifest ||= {
        "name" => @name,
        "version" => @agent_version,
        "bosh_protocol" => @bosh_protocol,
        "sha1" => @image_sha1,
        "cloud_properties" => {
          "root_device_name" => Bosh::Agent::StemCell::DEFAULT_DEVICE_NAME,
          "infrastructure" => @infrastructure,
          "architecture" => @architecture
        }
      }
    end

    protected

    # Cross-platform way of finding an executable in the $PATH.
    #
    #   which('ruby') #=> /usr/bin/ruby
    def which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = "#{path}/#{cmd}#{ext}"
          return exe if File.executable? exe
        end
      end
      return nil
    end

    # Execute the provide veewee command and return the exit status
    #
    # @param [String] command Execute the specified veewee command in @prefix
    # @@return Exitstatus of the Kernel#system command
    # @param [Hash] opts Options: :silent => when set to true, it raises :on_error exception
    def execute_veewee_cmd(command="", opts={})
      cmd = "veewee vbox #{command}"
      @logger.debug "Executing: #{cmd}"
      sh cmd, opts
    end

    # Package all files specified as arguments into a tar. The output file is specified by the :target option
    def package_files
      Dir.mktmpdir {|tmpdir|
        @stemcell_files.each {|file| FileUtils.cp(file, tmpdir) unless file.nil? } # only copy files that are not nil
        Dir.chdir(tmpdir) do
          @logger.info("Package #@stemcell_files to #@target ...")
          sh "tar -czf #@target * > /dev/null 2>&1", {:on_error => "unable to package #@stemcell_files into a stemcell"}
        end
      }
      @target
    end

    def sanity_check
      @logger.info "Sanity check"

      @logger.info "Checking target file: #@target..."
      if File.exists? @target
        @logger.warn "Target file #@target exists. Moving old file to #@target.bak."
        FileUtils.mv @target, "#@target.bak"
      end

      @logger.info "Checking agent source: #@agent_src_path"
      raise "Agent source #@agent_src_path doens't exist" unless File.exists? @agent_src_path

      @logger.info "Checking definitions dir..."
      raise "Definition for '#{type}' does not exist at path '#{definition_dir}'" unless Dir.exist? definition_dir
    end

    # @param [Hash] opts Options: :silent => when set to true, it raises :on_error exception
    # @param [String] cmd Command to execute
    def sh(cmd, opts={})
      unless opts[:on_error]
        opts[:on_error] = "Unable to execute: #{cmd}"
      end
      output = Kernel.system(cmd)
      @logger.debug(output) if output
      exit_status = $?.exitstatus

      # raise error only if silent is not true and exit_status != 0
      if exit_status != 0
        raise opts[:on_error] unless opts[:silent]
      end

      exit_status
    end

private

    # HACK: This is a compatibility hack for virtualbox
    # In virtualbox, upon doing an export, the 'vssd:VirtualSystemType' is set to 'virtualbox-2.2'
    # This causes problems when ESX tries to import the ovf file, we need to change it to 'vmx-07'
    def fix_virtualbox_ovf(filepath)
      if File.exists?(filepath)
        file_contents = File.read(filepath).gsub(/virtualbox-2.2/, "vmx-04 vmx-07 vmx-08")
        File.open(filepath, 'w') do |out|
          out << file_contents
        end
      end
    end

    # Packages the agent into a bosh_agent gem and copies it over to definition_dest_dir
    # so that it can be used as a part of the VM building process by veewee (using the definition).
    def package_agent
      @logger.debug "Packaging Bosh Agent to #{definition_dest_dir}/_bosh_agent.tar"
      dst = File.join(definition_dest_dir, "_bosh_agent.tar")
      if File.directory? @agent_src_path
        Dir.chdir(@agent_src_path) do
          sh("bundle package > /dev/null 2>&1 && gem build bosh_agent.gemspec > /dev/null 2>&1", {:on_error => "Unable to build Bosh Agent gem"})
          Dir.chdir(File.join(@agent_src_path, "vendor", "cache")) do
            sh("tar -cf #{dst} *.gem > /dev/null 2>&1", {:on_error => "Unable to package bosh gems"})
          end
          sh("tar -rf #{dst} *.gem > /dev/null 2>&1", {:on_error => "Unable to add bosh_agent gem to #{dst}"})
        end
      else
        Dir.chdir(File.dirname(@agent_src_path)) do
          sh("tar -cf #{dst} #@agent_src_path > /dev/null 2>&1", {:on_error => "Unable to package bosh agent gems"})
        end
      end
    end

    # Copies the veewee definition directory from ../templates/#@type to #@prefix/definitions/#@name
    def copy_definitions
      @logger.info "Creating definition dest dir"
      FileUtils.mkdir_p definition_dest_dir

      @logger.info "Copying definition from #{definition_dir} to #{definition_dest_dir}"
      FileUtils.cp_r Dir.glob("#{definition_dir}/*"), definition_dest_dir

      # Compile erb files
      Dir.glob(File.join(definition_dest_dir, '*.erb')) { |erb_file|
        compile_erb(erb_file)
      }
    end

    def definition_dir
      File.expand_path(@definition_dir ||= File.join(File.dirname(__FILE__), "..", "..", "templates", type))
    end

    def definition_dest_dir
      File.expand_path(@definition_dest_dir ||= File.join(@prefix, "definitions", @vm_name))
    end

    def gui?
      !!@gui
    end

    def compile_erb(erb_file, dst_file=nil)
      new_file_path = dst_file || erb_file.gsub(/\.erb$/,'')
      @logger.debug "Compiling erb #{erb_file} to #{new_file_path}"

      File.open(new_file_path, "w"){|f|
        f.write(ERB.new(File.read(File.expand_path(erb_file))).result(binding))
        File.delete erb_file
      }
    end

    def ssh_download_file(host,source, destination, options = {})
      require 'net/scp'

      downloaded_file_status = false
      Net::SCP.start(host, options[:user], { :port => options[:port] , :password => options[:password], :paranoid => false , :timeout => options[:timeout] }) do |scp|
        downloaded_file_status = scp.download!(source, destination)
      end
      downloaded_file_status
    end

  end
end

require 'stemcell/builders/ubuntu'
require 'stemcell/builders/redhat'
require 'stemcell/builders/centos'
require 'stemcell/builders/micro'
