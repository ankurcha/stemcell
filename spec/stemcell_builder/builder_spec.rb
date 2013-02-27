require 'spec_helper'
require 'yaml'

describe Bosh::Agent::StemCell::BaseBuilder do

  include Bosh::Agent::StemCell

  class NoOpBuilder < Bosh::Agent::StemCell::BaseBuilder

    attr_reader :build_vm_run, :package_stemcell_run, :setup_run, :cleanup_run

    def type
      "noop"
    end

    def initialize(opts)
      @counter = 0
      super(opts)
    end

    def build_vm
      @logger.info "Build VM invoked"
      @counter += 1
      @build_vm_run = @counter
    end

    def package_stemcell
      @logger.info "VM packaged into a stemcell"
      @counter += 1
      @package_stemcell_run = @counter
    end

    def setup
      @logger.info "Setting up stemcell creation process."
      @counter += 1
      @setup_run = @counter
    end

    def cleanup
      @logger.info "Perform cleanup"
      @counter += 1
      @cleanup_run = @counter
    end

    def init_default_iso
    end

  end

  class TestBuilder < Bosh::Agent::StemCell::BaseBuilder
    def type
      "noop"
    end
    def init_default_iso
      # Do nothing
    end
  end

  before(:each) do
    @prefix_dir = Dir.mktmpdir
    @agent_file = File.join(@prefix_dir, "bosh_agent-#{Bosh::Agent::VERSION}.gem")
    FileUtils.touch @agent_file
    @stemcell = TestBuilder.new({:prefix => @prefix_dir, :agent_src_path => @agent_file, :nogui => true, :log_level=>'WARN'})
  end

  after(:each) do
    target = File.expand_path(@stemcell.target)
    if File.exists?(target)
      FileUtils.rm_f target
      FileUtils.rm_f "#{target}.bak"
    end
  end


  it "Should initialize all default ISOs parameters properly" do
    @stemcell.iso.should be_nil
    @stemcell.iso_filename.should be_nil
    @stemcell.iso_md5.should be_nil
  end

  it "Should initialize all override ISOs properly" do
    @stemcell = TestBuilder.new({:prefix => @prefix_dir, :agent_src_path => @agent_file, :iso => "http://example.com/example.iso", :iso_md5 => "example-md5", :iso_filename => "example.iso", :log_level=>'WARN'})
    @stemcell.iso.should eq "http://example.com/example.iso"
    @stemcell.iso_md5.should eq "example-md5"
    @stemcell.iso_filename.should eq "example.iso"
  end

  it "Initializes the stemcell manifest with defaults" do
    defaults = {
        "name" => 'bosh-stemcell',
        "version" => Bosh::Agent::VERSION,
        "bosh_protocol" => Bosh::Agent::BOSH_PROTOCOL,
        "sha1" => nil,
        "cloud_properties" => {
            "root_device_name" => Bosh::Agent::StemCell::DEFAULT_DEVICE_NAME,
            "infrastructure" => 'vsphere',
            "architecture" => 'x86_64'
        }
    }

    @stemcell.manifest.should eq(defaults)

  end

  it "Initializes the options with defaults" do

    @stemcell.name.should eq "bosh-stemcell"
    @stemcell.infrastructure.should eq "vsphere"

  end

  it "Initializes the options with defaults and deep_merges the provided args" do
    override_stemcell = TestBuilder.new({:prefix => @prefix_dir, :agent_src_path => @agent_file, :log_level=>'WARN'})
    override_stemcell.name.should eq "bosh-stemcell"
    override_stemcell.type.should eq "noop"
  end

  it "Should return an initialized stemcell builder" do
    expect { Dir.exists? @stemcell.prefix }.to be_true
    expect { Dir.exists?("/var/tmp/bosh/agent-#{@stemcell.version}")|| Dir.exists?(Pathname.new(@stemcell.target_file).dirname) }.to be_true
  end

  it "Build VM works properly" do
    Kernel.should_receive(:system).with("veewee vbox build '#{@stemcell.vm_name}' --force --auto --nogui").and_return(true)
    Kernel.should_receive(:system).with("vagrant basebox export '#{@stemcell.vm_name}' --force").and_return(true)

    Kernel.should_receive(:system).with("veewee vbox destroy '#{@stemcell.vm_name}' --force --nogui").and_return(true)

    @stemcell.build_vm
  end

  it "Should have a properly initialized work directory" do
    expect { Dir.exists @stemcell.prefix }.to be_true
    expect { Dir.exists @stemcell.prefix }.to be_true
  end

  it "Compiles all the erb files as a part of the setup" do
    Dir.chdir(@prefix_dir) do
      @stemcell.setup
      filename = File.join(@prefix_dir, "definitions", @stemcell.vm_name, "erbtest.txt")
      regular_filename = File.join(@prefix_dir, "definitions", @stemcell.vm_name, "test.txt")
      File.exists?(filename).should eq true
      File.exists?(regular_filename).should eq true
      File.read(File.join(@prefix_dir, "definitions", @stemcell.vm_name, "erbtest.txt")).should eq @stemcell.name
      File.read(File.join(@prefix_dir, "definitions", @stemcell.vm_name, "test.txt")).should eq "## This is a test ##"
    end
  end

  it "Should invoke the methods in the correct order (setup -> build_vm -> package_vm -> finalize)" do

    @stemcell = NoOpBuilder.new({:prefix => @prefix_dir, :agent_src_path => @agent_file, :log_level=>'WARN'})

    @stemcell.run # all steps completed properly

    @stemcell.setup_run.should eq 1
    @stemcell.build_vm_run.should eq 2
    @stemcell.package_stemcell_run.should eq 3
    @stemcell.cleanup_run.should eq 4
  end

  it "Packages the stemcell contents correctly" do
    Dir.chdir(@prefix_dir) do
      # Create the box file
      FileUtils.touch "image-disk1.vmdk"
      File.open("image.ovf", "w")do |out|
        out << '<vssd:VirtualSystemType>virtualbox-2.2</vssd:VirtualSystemType>'
      end
      FileUtils.touch "Vagrantfile" # Unused
      system "tar -zcf #{File.join(@prefix_dir, @stemcell.vm_name)}.box image-disk1.vmdk image.ovf Vagrantfile"
    end

    @stemcell.package_stemcell()
    target = File.expand_path(@stemcell.target)

    File.exists?(target).should eq true # target is created

    Dir.chdir(Dir.mktmpdir) {
      system "tar -xzf #{target}"
      YAML.load_file("stemcell.MF").should eq @stemcell.manifest
      File.exists?("image").should be_true
      system "tar -xzf image"
      File.read("image.ovf").should eq '<vssd:VirtualSystemType>vmx-07</vssd:VirtualSystemType>'
    }
  end

end
