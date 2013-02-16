require 'veewee'
require 'deep_merge'
require 'erb'
require 'digest/md5'

module Bosh::Agent::StemCell

  # The source root is the path to the root directory of
  # the Veewee gem.
  def self.source_root
    @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
  end

  # This BaseBuilder abstract class represents the base stemcell builder and should be extended by specific stemcell
  # builders for different distributions
  class BaseBuilder

    attr_accessor :name, :infrastructure, :architecture
    attr_accessor :agent_src_path, :agent_version, :bosh_protocol
    attr_accessor :prefix, :target
    attr_accessor :iso, :iso_md5, :iso_filename
    attr_accessor :logger

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
      @name = opts[:name] || Bosh::Agent::StemCell::DEFAULT_STEMCELL_NAME
      @prefix = opts[:prefix] || Dir.pwd
      @infrastructure = opts[:infrastructure] || Bosh::Agent::StemCell::DEFAULT_INFRASTRUCTURE
      @architecture = opts[:architecture] || Bosh::Agent::StemCell::DEFAULT_ARCHITECTURE
      @agent_version = opts[:agent_version] || Bosh::Agent::VERSION
      @bosh_protocol = opts[:agent_protocol] || Bosh::Agent::BOSH_PROTOCOL
      @agent_src_path = File.expand_path(opts[:agent_src_path] || "./bosh_agent-#{@agent_version}.gem")
      @target = File.expand_path( @target || File.join(@prefix, "bosh-#{type}-#{@agent_version}.tgz"))
      @iso = opts[:iso]
      @iso_md5 = opts[:iso_md5]

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
        execute_veewee_cmd "build '#@name' --force --nogui --auto", {:on_error => "Unable to build vm #@name"}

        @logger.info "Export built VM #@name to #@prefix"
        system "vagrant basebox export '#@name' --force", {:on_error => "Unable to export VM #@name: vagrant basebox export '#@name'"}

        @logger.debug "Sending veewee destroy for #@name"
        execute_veewee_cmd "destroy '#@name' --force --nogui"
      end

    end

    def type
      raise "Type must be initialized"
    end

    def init_default_iso
      raise "Default ISO options must be provided"
    end

    # Packages the stemcell contents (defined as the array of file path argument)
    def package_stemcell
      generate_image
      generate_manifest
      generate_pkg_list

      package_files "image", "stemcell.MF", "stemcell_dpkg_l.txt"
    end

    def generate_manifest
      stemcell_mf_path = File.expand_path "stemcell.MF", @prefix
      File.open(stemcell_mf_path, "w") do |f|
        f.write(manifest.to_yaml)
      end
    end

    def generate_image
      Dir.chdir(@prefix) do
        system("tar -xzf #{@name}.box", {:on_error => "Unable to unpack .box file"})
        system("tar -czf image *.vmdk *.ovf", {:on_error=>"Unable to create image file from ovf and vmdk"})
      end
    end

    def generate_pkg_list
      FileUtils.touch File.join(@prefix, "stemcell_dpkg_l.txt")
    end

    # Main execution method that sets up the directory, builds the VM and packages everything into a stemcell
    def run
      setup
      build_vm
      package_stemcell
    end

    def manifest
      @manifest ||= {
        :name => @name,
        :version => @agent_version,
        :bosh_protocol => @bosh_protocol,
        :cloud_properties => {
          :root_device_name => Bosh::Agent::StemCell::DEFAULT_DEVICE_NAME,
          :infrastructure => @infrastructure,
          :architecture => @architecture
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
      system cmd, opts
    end

    # Package all files specified as arguments into a tar. The output file is specified by the :target option
    def package_files(*files)
      files_str = files.join(" ")
      @logger.info "Packaging #{files_str} to #@target"

      Dir.chdir(@prefix) do
        system("tar -czf #{@target} #{files_str}", {:on_error => "unable to package #{files_str} into a stemcell"})
      end
    end

private

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

    # Packages the agent into a bosh_agent gem and copies it over to definition_dest_dir
    # so that it can be used as a part of the VM building process by veewee (using the definition).
    def package_agent
      @logger.debug "Packaging Bosh Agent to #{definition_dest_dir}/_bosh_agent.tar"
      dst = File.join(definition_dest_dir, "_bosh_agent.tar")
      if File.directory? @agent_src_path
        Dir.chdir(@agent_src_path) do
          system("bundle package && gem build bosh_agent.gemspec", {:on_error => "Unable to build Bosh Agent gem"})
          Dir.chdir(File.join("vendor", "cache")) do
            system("tar -cf #{dst} *.gem", {:on_error => "Unable to package bosh gems"})
          end
          system("tar -rf #{dst} *.gem", {:on_error => "Unable to add bosh_agent gem to #{dst}"})
        end
      else
        Dir.chdir(File.dirname(@agent_src_path)) do
          system("tar -cf #{dst} #@agent_src_path", {:on_error => "Unable to package bosh agent gems"})
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
      File.join(File.dirname(__FILE__), "..", "..", "templates", type)
    end

    def definition_dest_dir
      File.expand_path File.join(@prefix, "definitions", @name)
    end

    def compile_erb(erb_file, dst_file=nil)
      new_file_path = dst_file || erb_file.gsub(/\.erb$/,'')
      @logger.debug "Compiling erb #{erb_file} to #{new_file_path}"

      File.open(new_file_path, "w"){|f|
        f.write(ERB.new(File.read(File.expand_path(erb_file))).result(binding))
        File.delete erb_file
      }
    end

    # @param [Hash] opts Options: :silent => when set to true, it raises :on_error exception
    # @param [String] cmd Command to execute
    def system(cmd, opts={})
      unless opts[:on_error]
        opts[:on_error] = "Unable to execute: #{cmd}"
      end

      Kernel.system(cmd)
      exit_status = $?.exitstatus

      # raise error only if silent is not true and exit_status != 0
      raise opts[:on_error] unless opts[:silent] if exit_status != 0

      exit_status
    end

  end
end

require 'stemcell/builders/noop'
require 'stemcell/builders/ubuntu'
require 'stemcell/builders/redhat'
require 'stemcell/builders/centos'
