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

  class BaseBuilder

    attr_accessor :manifest

    def initialize(opts = {}, manifest={})
      initialize_instance_vars(opts)
      @manifest = merge_manifest(manifest)

      # initialize vars
      @target = "bosh-#@type-#@agent_version.tgz" unless @target
      @logger.info "Using target file: #@target"

      if File.exists? @target
        @logger.warn "Target file #@target exists. Moving old file to #@target.bak."
        FileUtils.mv @target, "#@target.bak"
      end

    end

    # This method does the setup, this implementation takes care of copying over the
    # correct definition files, packaging the agent and doing any related setup if needed
    def setup
      @logger.info "Setting up files in #@prefix"
      copy_definitions
      package_agent
    end

    # This method creates the vm using the name as the vm name
    def build_vm
      @logger.info "Building vm #@name"
      unless execute_veewee_cmd "build '#@name' --force --nogui --auto"
        raise "Unable to build vm #@name"
      end

      @logger.info "Export built VM #@name to #@prefix"
      unless Kernel.system "vagrant basebox export '#@name'"
        raise "Unable to export VM #@name: vagrant basebox export '#@name'"
      end

      @logger.debug "Sending veewee destroy for #@name"
      execute_veewee_cmd "destroy '#@name'"

    end

    # Packages the stemcell contents (defined as the array of file path argument),
    # Subclasses can add more behavior and files to the files arguments.
    #
    # @param [Array] files List of file paths that need to be packaged
    def package_stemcell(files=[])
      unless files.empty?
        files_str = files.join(" ")
        @logger.info "Packaging #{files_str} to #@target"
        unless Kernel.system("tar -cvf #@target #{files_str}")
          raise "unable to package #{files_str} into a stemcell"
        end
      end
    end

    # Main execution method that sets up, builds the VM and packages the stemcell
    def run
      Dir.chdir(@prefix) do
        setup
        build_vm
        package_stemcell
      end
    end

    protected

    # Cross-platform way of finding an executable in the $PATH.
    #
    #   which('ruby') #=> /usr/bin/ruby
    def which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
          exe = "#{path}/#{cmd}#{ext}"
          return exe if File.executable? exe
        }
      end
      return nil
    end

    # Execute the provide veewee command with the correct container in @prefix and return the
    # exit status
    #
    # @param [String] command Execute the specified veewee command in @prefix
    # @@return Exitstatus of the Kernel#system command
    def execute_veewee_cmd(command="")
      cmd = "veewee #@container #{command}"
      @logger.debug "Executing: #{cmd}"
      Kernel.system cmd
    end


    private
    def initialize_instance_vars(opts={})
      #merge options and defaults and initialize instance variables
      agent_version = Bosh::Agent::VERSION
      bosh_protocol = Bosh::Agent::BOSH_PROTOCOL
      agent_gem_file = File.expand_path("bosh_agent-#{agent_version}.gem", Dir.pwd)
      definitions_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", 'templates'))
      merged_opts = opts.deep_merge({:name => 'bosh-stemcell',
                              :logger => Logger.new(STDOUT),
                              :target => nil,
                              :container => 'vbox',
                              :infrastructure => 'vsphere',
                              :definitions_dir => definitions_dir,
                              :type => nil,
                              :agent_src_path => agent_gem_file,
                              :agent_version => agent_version, :bosh_protocol => bosh_protocol,
                              :architecture => 'x86_64',
                              :prefix => Dir.pwd,
                              :iso => nil,
                              :iso_md5 => nil,
                              :iso_filename => nil
                             })
      merged_opts.each do |k, v|
        instance_variable_set("@#{k}", v)
        # if you want accessors:
        eigenclass = class<<self;
          self
        end
        eigenclass.class_eval do
          attr_accessor k
        end
      end

      if @iso
        unless @iso_md5
          raise "MD5 must be specified is ISO is specified"
        end
        unless @iso_filename
          @iso_filename = File.basename @iso
        end
      end
      # Simple debug loop
      opts.each do |key, value|
        @logger.debug "Setting #{key} = #{value}"
      end
    end

    # This method creates the stemcell manifest
    def merge_manifest(manifest={})
      # perform a deep_merge of the provided manifest with the defaults
      manifest.deep_merge({
                              :name => @name,
                              :version => @agent_version,
                              :bosh_protocol => @bosh_protocol,
                              :cloud_properties => {
                                  :infrastructure => @infrastructure,
                                  :architecture => @architecture
                              }
                          })
    end

    # Packages the agent into a bosh_agent gem and copies it over to @definition_dest_path
    # so that it can be used as a part of the VM building process by veewee (using the definition).
    def package_agent
      @logger.debug "Packaging Bosh Agent to #@definition_dest_path/bosh_agent.gem"
      if File.directory? @agent_src_path
        Dir.chdir(@agent_src_path) do
          unless Kernel.system("gem build bosh_agent.gemspec")
            raise "Unable to build Bosh Agent gem"
          end
        end
        # copy gem to definitions
        FileUtils.mv(File.join(@agent_src_path, "bosh_agent-#@agent_version.gem"), File.join(@definition_dest_path, "_bosh_agent.gem"))
      else
        FileUtils.cp @agent_src_path, File.join(@definition_dest_path, "_bosh_agent.gem")
      end
    end

    # Copies the veewee definition directory from ../definition/@type to @prefix/definitions/@name
    def copy_definitions
      definition_src_path = File.join(@definitions_dir, @type)
      @logger.info "TYPE: #@type"
      @definition_dest_path = File.join('definitions', @name)

      @logger.info "Copying definition from #{definition_src_path} to #@definition_dest_path"

      if Dir.exists?(definition_src_path)
        FileUtils.mkdir_p @definition_dest_path
        FileUtils.cp_r Dir.glob("#{definition_src_path}/*"), @definition_dest_path

        # Compile erb files
        Dir.glob(File.join(@definition_dest_path, '*.erb')) { |erb_file|
          new_file_path = erb_file.gsub(/\.erb$/,'')
          @logger.info "Compiling erb #{erb_file} to #{new_file_path}"

          File.open(new_file_path, "w"){|f|
            f.write(ERB.new(File.read(File.expand_path(erb_file))).result(binding))
            File.delete erb_file
          }
        }

      else
        raise "Definition for '#{type}' does not exist at path '#{definition_src_path}'"
      end
    end

  end
end

require 'builders/noop'
require 'builders/ubuntu'
require 'builders/redhat'
require 'builders/version'