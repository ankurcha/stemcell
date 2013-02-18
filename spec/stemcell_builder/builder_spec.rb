require 'spec_helper'

describe Bosh::Agent::StemCell::BaseBuilder do

  include Bosh::Agent::StemCell

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
    @stemcell = TestBuilder.new({:prefix => @prefix_dir, :agent_src_path => @agent_file, :nogui => true})
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
    @stemcell = TestBuilder.new({:prefix => @prefix_dir, :agent_src_path => @agent_file, :iso => "http://example.com/example.iso", :iso_md5 => "example-md5", :iso_filename => "example.iso"})
    @stemcell.iso.should eq "http://example.com/example.iso"
    @stemcell.iso_md5.should eq "example-md5"
    @stemcell.iso_filename.should eq "example.iso"
  end

  it "Initializes the stemcell manifest with defaults" do
    defaults = {
        :name => 'bosh-stemcell',
        :version => Bosh::Agent::VERSION,
        :bosh_protocol => Bosh::Agent::BOSH_PROTOCOL,
        :cloud_properties => {
            :root_device_name => Bosh::Agent::StemCell::DEFAULT_DEVICE_NAME,
            :infrastructure => 'vsphere',
            :architecture => 'x86_64'
        }
    }

    @stemcell.manifest.should eq(defaults)

  end

  it "Initializes the options with defaults" do

    @stemcell.name.should eq "bosh-stemcell"
    @stemcell.infrastructure.should eq "vsphere"

  end

  it "Initializes the options with defaults and deep_merges the provided args" do
    override_stemcell = TestBuilder.new({:prefix => @prefix_dir, :agent_src_path => @agent_file})
    override_stemcell.name.should eq "bosh-stemcell"
    override_stemcell.type.should eq "noop"
  end

  it "Should return an initialized stemcell builder" do
    expect { Dir.exists? @stemcell.prefix }.to be_true
    expect { Dir.exists?("/var/tmp/bosh/agent-#{@stemcell.version}")|| Dir.exists?(Pathname.new(@stemcell.target_file).dirname) }.to be_true
  end

  it "Build VM works properly" do
    # Expectations
    Kernel.should_receive(:system).with("veewee vbox build '#{@stemcell.name}' --force --auto --nogui").and_return(true)
    Kernel.should_receive(:system).with("vagrant basebox export '#{@stemcell.name}' --force").and_return(true)

    Kernel.should_receive(:system).with("veewee vbox destroy '#{@stemcell.name}' --force --nogui").and_return(true)

    @stemcell.build_vm
  end

  it "Should have a properly initialized work directory" do
    expect { Dir.exists @stemcell.prefix }.to be_true
    expect { Dir.exists @stemcell.prefix }.to be_true
  end

  it "Compiles all the erb files as a part of the setup" do
    Dir.chdir(@prefix_dir) do
      @stemcell.setup
      filename = File.join(@prefix_dir, "definitions", @stemcell.name, "erbtest.txt")
      regular_filename = File.join(@prefix_dir, "definitions", @stemcell.name, "test.txt")
      File.exists?(filename).should eq true
      File.exists?(regular_filename).should eq true
      File.read(File.join(@prefix_dir, "definitions", @stemcell.name, "erbtest.txt")).should eq @stemcell.name
      File.read(File.join(@prefix_dir, "definitions", @stemcell.name, "test.txt")).should eq "## This is a test ##"
    end
  end

  it "Should invoke the methods in the correct order (setup -> build_vm -> package_vm -> finalize)" do

    @stemcell = Bosh::Agent::StemCell::NoOpBuilder.new({:prefix => @prefix_dir, :agent_src_path => @agent_file})

    @stemcell.run # all steps completed properly

    @stemcell.setup_run.should eq 1
    @stemcell.build_vm_run.should eq 2
    @stemcell.package_stemcell_run.should eq 3
  end

  it "Packages the stemcell contents correctly" do
    require 'yaml'

    Dir.chdir(@prefix_dir) {
      # Create the box file
      FileUtils.touch "box-disk1.vmdk"
      FileUtils.touch "box.ovf"
      FileUtils.touch "Vagrantfile" # Unused
      system "tar -czf #{@stemcell.name}.box box-disk1.vmdk box.ovf Vagrantfile"
    }

    @stemcell.package_stemcell()
    target = File.expand_path(@stemcell.target)

    File.exists?(target).should eq true # target is created

    Dir.mktmpdir { |tmpdir|
      system "tar -C #{tmpdir} -xzf #{target} stemcell.MF"
      YAML.load_file(File.expand_path("stemcell.MF", tmpdir)).should eq @stemcell.manifest
    }
  end

end
