require 'spec_helper'

describe Bosh::Agent::StemCell::UbuntuBuilder do


  before(:each) do
    @agent_file = File.join("bosh-agent.gem")
    FileUtils.touch @agent_file
    @stemcell = Bosh::Agent::StemCell::UbuntuBuilder.new({:agent_src_path => @agent_file, :log_level=>'ERROR'})
  end

  after(:each) do
    FileUtils.rm_f @agent_file
  end

  it "Should initialize type properly" do
    @stemcell.type.should eq "ubuntu"
  end

  it "Should initialize the manifest should properly" do
    @stemcell.manifest.values_at("cloud_properties").should_not be_nil
    @stemcell.manifest["cloud_properties"]["root_device_name"].should eq '/dev/sda1'
  end

  it "Should initialize all options properly" do
    @stemcell.iso.should eq "http://releases.ubuntu.com/11.04/ubuntu-11.04-server-amd64.iso"
    @stemcell.iso_md5.should eq "355ca2417522cb4a77e0295bf45c5cd5"
    @stemcell.iso_filename.should eq "ubuntu-11.04-server-amd64.iso"
  end

  it "Should initialize override options properly" do
    @stemcell = Bosh::Agent::StemCell::UbuntuBuilder.new({:agent_src_path => @agent_file, :iso => "http://example.com/ubuntu.iso", :iso_md5 => "123", :iso_filename => "ubuntu.iso", :log_level=>'ERROR'})
    @stemcell.iso.should eq "http://example.com/ubuntu.iso"
    @stemcell.iso_md5.should eq "123"
    @stemcell.iso_filename.should eq "ubuntu.iso"
  end

end
