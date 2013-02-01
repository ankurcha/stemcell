require 'spec_helper'

describe Bosh::Agent::StemCell::BaseBuilder do

  before(:each) do
    @log = Logger.new(STDOUT)
    @log.level = Logger::WARN
    @stemcell = Bosh::Agent::StemCell::BaseBuilder.new({:type => "testing-stemcell", :logger => @log}, {})
  end

  it "Initializes the stemcell manifest with defaults" do
    defaults = {
        :name => 'bosh-stemcell',
        :version => Bosh::Agent::VERSION,
        :bosh_protocol => Bosh::Agent::BOSH_PROTOCOL,
        :cloud_properties => {
            :infrastructure => 'vsphere',
            :architecture => 'x86_64'
        }
    }

    @stemcell.manifest.should eq(defaults)

  end

  it "Initializes the stemcell manifest with defaults and deep_merges the provided args" do
    manifest = {
        :name => 'test-stemcell-name',
        :version => Bosh::Agent::VERSION,
        :bosh_protocol => Bosh::Agent::BOSH_PROTOCOL,
        :cloud_properties => {
            :infrastructure => 'vsphere',
            :architecture => 'x86_64',
            :key => 'value'
        }
    }

    override_stemcell = Bosh::Agent::StemCell::BaseBuilder.new({:type => "testing-stemcell", :logger => @log}, {:name => 'test-stemcell-name',:cloud_properties => {:key => 'value'}})

    override_stemcell.manifest.should eq(manifest)
  end

  it "Initializes the options with defaults" do

    @stemcell.name.should eq "bosh-stemcell"
    @stemcell.container.should eq "vbox"
    @stemcell.infrastructure.should eq "vsphere"

  end

  it "Initializes the options with defaults and deep_merges the provided args" do
    override_stemcell = Bosh::Agent::StemCell::BaseBuilder.new({:type => "testing-stemcell", :logger => @log}, {:name => 'test-stemcell-name',:cloud_properties => {:key => 'value'}})
    override_stemcell.name.should eq "bosh-stemcell"
    override_stemcell.type.should eq "testing-stemcell"
  end

  it "Should return an initialized stemcell builder" do
    expect { Dir.exists? @stemcell.prefix }.to be_true
    expect { Dir.exists?("/var/tmp/bosh/agent-#{@stemcell.version}")|| Dir.exists?(Pathname.new(@stemcell.target_file).dirname) }.to be_true
  end

  it "Build VM works properly" do
    # Expectations
    Kernel.should_receive(:system).with("veewee #{@stemcell.container} build '#{@stemcell.name}' --force --nogui --auto").and_return(true)
    Kernel.should_receive(:system).with("vagrant basebox export '#{@stemcell.name}'").and_return(true)

    Kernel.should_receive(:system).with("veewee vbox destroy '#{@stemcell.name}'").and_return(true)

    @stemcell.build_vm
  end

  it "Should have a properly initialized work directory" do
    expect { Dir.exists @stemcell.prefix }.to be_true
    expect { Dir.exists @stemcell.prefix }.to be_true
  end

  it "Should invoke the methods in the correct order (setup -> build_vm -> package_vm -> finalize)" do

    @stemcell = Bosh::Agent::StemCell::NoOpBuilder.new({:logger => @log}, {})

    @stemcell.run # all steps completed properly

    @stemcell.setup_run.should eq 1
    @stemcell.build_vm_run.should eq 2
    @stemcell.package_stemcell_run.should eq 3
  end

end