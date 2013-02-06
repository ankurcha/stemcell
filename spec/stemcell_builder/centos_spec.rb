require 'spec_helper'

describe Bosh::Agent::StemCell::CentosBuilder do


  before(:each) do
    @agent_file = File.join("bosh-agent.gem")
    FileUtils.touch @agent_file
    @stemcell = Bosh::Agent::StemCell::CentosBuilder.new({:agent_src_path => @agent_file}, {})
  end

  after(:each) do
    FileUtils.rm_f @agent_file
  end

  it "Should initialize the manifest should properly" do
    @stemcell.manifest.values_at(:cloud_properties).should_not be_nil
    @stemcell.manifest[:cloud_properties][:root_device_name].should eq '/dev/sda1'
  end

  it "Should initialize default iso options properly" do
    @stemcell.iso.should eq "http://www.mirrorservice.org/sites/mirror.centos.org/6.3/isos/x86_64/CentOS-6.3-x86_64-minimal.iso"
    @stemcell.iso_md5.should eq "087713752fa88c03a5e8471c661ad1a2"
    @stemcell.iso_filename.should eq "CentOS-6.3-x86_64-minimal.iso"
  end

  it "Should initialize type properly" do
    @stemcell.type.should eq "centos"
  end

end
