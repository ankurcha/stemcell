require 'logger/colors'
require 'deep_merge'
require 'erb'
require 'securerandom'
require 'digest/sha1'
require 'net/scp'
require 'net/ssh'
require 'retryable'
require 'tmpdir'

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
      initialize_common(opts)
      initialize_micro(opts) if micro?
      sanity_check
    end

    # This method does the setup, this implementation takes care of copying over the
    # correct definition files, packaging the agent and doing any related setup if needed
    def setup
      copy_definitions
      package_agent
    end

    def micro?
      !!@micro
    end

    # This method creates the vm using the #@name as the virtual machine name
    # If an existing VM exists with the same name, it will be deleted.
    def build_vm
      Dir.chdir(@prefix) do
        @logger.info "Building vm #@name"
        nogui_str = gui? ? "" : "--nogui"

        sh "veewee vbox build '#@vm_name' --force --auto #{nogui_str}", {:on_error => "Unable to build vm #@name"}

        # execute pre-shutdown hook
        pre_shutdown_hook

        @logger.info "Export built VM #@name to #@prefix"
        sh "vagrant basebox export '#@vm_name' --force", {:on_error => "Unable to export VM #@name: vagrant basebox export '#@vm_name'"}
      end

    end

    def pre_shutdown_hook
      if micro?
        convert_stemcell_to_micro
      end
    end

    def type
      raise NotImplementedError.new("Type must be initialized")
    end

    def init_default_iso
      raise NotImplementedError.new("Default ISO options must be provided")
    end

    # Packages the stemcell contents (defined as the array of file path argument)
    def package_stemcell
      @stemcell_files << generate_image << generate_manifest
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
        sh("tar -xf #@vm_name.box", {:on_error => "Unable to unpack .box file"})
        vmdk_filename = Dir.glob("*.vmdk").first
        Dir.glob("*.ovf") { |ovf_file| fix_virtualbox_ovf(ovf_file, vmdk_filename) } # Fix ovf files
        sh("tar -czf #{image_path} *.vmdk *.ovf", {:on_error=>"Unable to create image file from ovf and vmdk"})
        FileUtils.rm [Dir.glob('*.box'), Dir.glob('*.vmdk'), Dir.glob('*.ovf'), "Vagrantfile"]
        @image_sha1 = Digest::SHA1.file(image_path).hexdigest
      end
      image_path
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

    # Package all files specified as arguments into a tar. The output file is specified by the :target option
    def package_files
      Dir.mktmpdir {|tmpdir|
        @stemcell_files.flatten.each {|file| FileUtils.cp(file, tmpdir) if file && File.exists?(file) } # only copy files that are not nil
        Dir.chdir(tmpdir) do
          @logger.info("Package #@stemcell_files to #@target ...")
          sh "tar -czf #@target *", {:on_error => "unable to package #@stemcell_files into a stemcell"}
        end
      }
      @target
    end

    def sanity_check
      @logger.info "Sanity check"

      @logger.info "Checking ssh_port"
      raise "Unable to find port for ssh" if @ssh_port.nil?

      @logger.info "Checking target file: #@target..."
      if File.exists? @target
        @logger.warn "Target file #@target exists. Moving old file to #@target.bak."
        FileUtils.mv @target, "#@target.bak"
      end

      @logger.info "Checking agent source: #@agent_src_path"
      raise "Agent source #@agent_src_path doens't exist" unless File.exists? @agent_src_path

      @logger.info "Checking definitions dir..."
      raise "Definition for '#{type}' does not exist at path '#{definition_dir}'" unless Dir.exist? definition_dir

      if micro?
        @logger.info "Checking micro stemcell conversion files"
        raise "Micro conversion script does not exist." unless File.exists?(@micro_path)
        raise "Release manifest path missing"           unless File.exists?(@release_manifest)
        raise "Release tar path missing"                unless File.exists?(@release_tar)
        raise "Package compiler path missing"           unless File.exists?(@package_compiler_tar)
      end

    end

    # @param [Hash] opts Options: :silent => when set to true, it raises :on_error exception
    # @param [String] cmd Command to execute
    def sh(cmd, opts={})
      unless opts[:on_error]
        opts[:on_error] = "Unable to execute: #{cmd}"
      end
      Kernel.system(cmd)
      exit_status = $?.exitstatus

      # raise error only if silent is not true and exit_status != 0
      if exit_status != 0
        raise opts[:on_error] unless opts[:silent]
      end

      exit_status
    end

    def ssh_options
      {
          :host => '127.0.0.1',
          :user => 'vcap',
          :password => 'c1oudc0w',
          :port => @ssh_port,
          :paranoid => false,
          :timeout => 30
      }
    end

    def filter_ssh_opts
      opts = ssh_options.dup
      opts.delete(:host) if opts.has_key?(:host)
      opts.delete(:user) if opts.has_key?(:user)
      opts
    end

    def ssh_execute(cmd)
      @logger.info "Executing #{cmd} on VM [ options: #{filter_ssh_opts} ]"
      Net::SSH.start(ssh_options[:host], ssh_options[:user], filter_ssh_opts) do |ssh|
        ssh.exec! "echo '#{ssh_options[:password]}' | sudo -S /bin/bash '#{cmd}'" do |ch, stream, line|
          @logger.info line
        end
      end
    end

    def upload_file(source, destination=nil)
      destination ||= "/home/#{ssh_options[:user]}"

      retryable(:tries => 5, :sleep => 5) do |retries, exception|
        @logger.warn "Failed to upload :#{exception}" unless exception.nil?
        @logger.info "Attempting to upload #{source} to #{destination} [ options: #{filter_ssh_opts} ]"
        Net::SCP.start(ssh_options[:host], ssh_options[:user], filter_ssh_opts) do |scp|
          scp.upload!(source, destination) do|ch, name, sent, total|
            print "\r#{name}: #{(sent.to_f * 100 / total.to_f).to_i}%"
          end
        end
      end
    end

    def download_file(source, destination=nil)
      destination ||= File.join(@prefix, File.basename(source))

      retryable(:tries => 5, :sleep => 5) do |retries, exception|
        @logger.warn "Failed to download :#{exception}" unless exception.nil?
        @logger.info "Attempting to download #{source} to #{destination} [ options: #{filter_ssh_opts} ]"
        Net::SCP.start(ssh_options[:host], ssh_options[:user], filter_ssh_opts) do |scp|
          scp.download!(source, destination) do|ch, name, sent, total|
            print "\r#{name}: #{(sent.to_f * 100 / total.to_f).to_i}%"
          end
        end
      end
      @logger.warn "Unable to download #{source}" unless File.exists?(destination)
    end

private

    def get_free_port
      port = nil
      begin
        socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
        socket.bind(Addrinfo.tcp("127.0.0.1", 0))
        port = socket.local_address.ip_port
      ensure
        socket.close
      end
      port
    end

    # HACK: This is a compatibility hack for virtualbox-esx compatibility
    def fix_virtualbox_ovf(filepath, vmdk_filename="box-disk1.vmdk")
      @logger.info "Generating ovf file for virtual machine"
      @vmdk_filename = vmdk_filename
      vmware_ovf_erb = File.join(File.dirname(__FILE__), "..", "..", "assets", "box.ovf.erb")
      compile_erb(vmware_ovf_erb, filepath)
    end

    # Packages the agent into a bosh_agent gem and copies it over to definition_dest_dir
    # so that it can be used as a part of the VM building process by veewee (using the definition).
    def package_agent
      @logger.info "Packaging Bosh Agent to #{definition_dest_dir}/_bosh_agent.tar"
      dst = File.join(definition_dest_dir, "_bosh_agent.tar")
      if File.directory? @agent_src_path
        @logger.info "Tarring up Bosh Agent"
        Dir.chdir(@agent_src_path) do
          sh("tar -cf #{dst} *.gem > /dev/null 2>&1", {:on_error => "Unable to package bosh gems"})
        end
      else
        FileUtils.cp @agent_src_path, dst
      end
    end

    # Copies the veewee definition directory from ../templates/#@type to #@prefix/definitions/#@name
    def copy_definitions
      @logger.info "Creating definition dest dir"
      if Dir.exists? definition_dest_dir
        @logger.warn "#{definition_dest_dir} already exists, contents will be deleted"
        FileUtils.rm_rf definition_dest_dir
      end
      FileUtils.mkdir_p definition_dest_dir

      @logger.info "Copying definition from #{definition_dir} to #{definition_dest_dir}"
      FileUtils.cp_r Dir.glob("#{definition_dir}/*"), definition_dest_dir

      # Compile erb files
      Dir.glob(File.join(definition_dest_dir, '*.erb')) { |erb_file|
        compile_erb(erb_file) # compile erb
        FileUtils.rm erb_file # remove original
      }
    end

    def definition_dir
      File.expand_path(@definition_dir ||= File.join(File.dirname(__FILE__), "..", "..", "templates", type))
    end

    def definition_dest_dir
      File.expand_path(@definition_dest_dir ||= File.join(@prefix, "definitions", @vm_name))
    end

    def compile_erb(erb_file, dst_file=nil)
      new_file_path = dst_file || erb_file.gsub(/\.erb$/,'')
      @logger.debug "Compiling erb #{erb_file} to #{new_file_path}"

      File.open(new_file_path, "w"){|f|
        f.write(ERB.new(File.read(File.expand_path(erb_file))).result(binding))
      }
    end

    def gui?
      !!@gui
    end

    def initialize_common(opts)
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
      @micro = opts[:micro]
      @ssh_port = opts[:ssh_port] || get_free_port()

      if @iso
        raise "MD5 must be specified is ISO is specified" unless @iso_md5
        @iso_filename ||= File.basename @iso
      else
        init_default_iso
      end
    end

    def initialize_micro(opts)
      @logger.info "Initializing micro stemcell artifacts"
      #@bosh_src_root = opts[:bosh_src_root] || File.expand_path("bosh", @prefix)
      @release_manifest = opts[:release_manifest] # || default_release_manifest
      @release_tar = opts[:release_tar]
      @package_compiler_tar = opts[:package_compiler]
      @micro_path = opts[:micro_path] || File.join(definition_dir, "micro.sh")

      # This is kind of a hack :(
      if File.exists?(@package_compiler_tar) && File.directory?(@package_compiler_tar)
        # Tar up the package
        tmpdir = Dir.mktmpdir
        tmp_package_compiler_tar = File.join(tmpdir, "_package_compiler.tar")
        Dir.chdir(opts[:package_compiler]) do
          sh "tar -cf #{tmp_package_compiler_tar} *"
          @package_compiler_tar = tmp_package_compiler_tar
        end
      end

    end

    def build_all_deps
      @logger.info "Build all bosh packages with dependencies from source"
      @logger.info "Execute 'rake all:build_with_deps' in bosh/ directory"
    end

    def create_release_tarball
      @logger.info("Copy bosh/release/config/microbosh-dev-template.yml to bosh/release/config/dev.yml")
      @logger.info("Then execute 'bosh create release --force --with-tarball'")
      @logger.info("The release tar will be in bosh/release/dev_releases/micro-bosh*.tgz")
      @logger.info("The release manifest is at bosh/release/micro/vsphere.yml")
    end

    def convert_stemcell_to_micro
      # SCP upload _release.tgz, _package_compiler.tar, _release.yml, micro.sh
      upload_file @package_compiler_tar, "/home/vcap/_package_compiler.tar"
      upload_file @release_tar, "/home/vcap/_release.tgz"
      upload_file @release_manifest, "/home/vcap/_release.yml"
      upload_file @micro_path, "/home/vcap/micro.sh"
      # SSH execute micro.sh
      @logger.info ssh_execute("./micro.sh")

      # SCP download apply.spec
      download_file "/var/vcap/micro/apply_spec.yml"
      @stemcell_files << File.join(@prefix, "apply_spec.yml")
    end

  end
end

require 'stemcell/builders/ubuntu'
require 'stemcell/builders/redhat'
require 'stemcell/builders/centos'
