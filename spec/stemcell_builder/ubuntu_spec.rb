require 'spec_helper'

describe Bosh::Agent::StemCell::UbuntuBuilder do


  before(:each) do
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @prefix_dir = Dir.mktmpdir
    @agent_file = File.join(@prefix_dir, "bosh-agent.gem")
    FileUtils.touch @agent_file

    @stemcell = Bosh::Agent::StemCell::UbuntuBuilder.new({:logger => @log, :prefix => @prefix_dir, :agent_src_path => @agent_file}, {})
  end

  it "Should initialize the manifest should properly" do
    @stemcell.manifest.should eq({
                                     :name => 'bosh-stemcell',
                                     :version => Bosh::Agent::VERSION,
                                     :bosh_protocol => Bosh::Agent::BOSH_PROTOCOL,
                                     :cloud_properties => {
                                         :infrastructure => 'vsphere',
                                         :architecture => 'x86_64',
                                         :root_device_name => '/dev/sda1'
                                     }
                                 })
  end

  it "Should initialize all options properly" do
    @stemcell.iso.should eq "http://releases.ubuntu.com/11.04/ubuntu-11.04-server-amd64.iso"
    @stemcell.iso_md5.should eq "355ca2417522cb4a77e0295bf45c5cd5"
    @stemcell.iso_filename.should eq "ubuntu-11.04-server-amd64.iso"
    @stemcell.type.should eq "ubuntu"
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

  after(:each) do
    target = File.expand_path(@stemcell.target)
    if File.exists?(target)
      @log.info "Removing #{target}"
      FileUtils.rm_f target
      FileUtils.rm_f "#{target}.bak"
    end

  end

end