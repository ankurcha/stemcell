module Bosh::Agent::StemCell

  class UbuntuBuilder < BaseBuilder

    def package_stemcell(files=[])
      # unbox the exported thing
      unless system "tar -xzf #{File.expand_path("#@name.box", @prefix)}"
        raise "Unable to unpack exported .box file"
      end
      # tar up the vmdk, ovf files to 'image'
      image_path = File.expand_path "image", @prefix
      stemcell_mf_path = File.expand_path "stemcell.MF", @prefix
      legal_package_list = File.expand_path "stemcell_dpkg_l.txt"

      unless system "tar -cvf #{image_path} *.vmdk *.ovf"
        raise "Unable to create image tar from ovf and vmdk"
      end

      # Create the stemcell manifest
      File.open(stemcell_mf_path, "w") do |f|
        f.write(@manifest.to_yaml)
      end

      files.push image_path, stemcell_mf_path
      # pass to super for rest of the work
      super(files)
    end

    def initialize(opts={}, manifest={:cloud_properties => {:root_device_name => '/dev/sda1'}})
      super(opts.deep_merge({:type => 'ubuntu',
             :iso => 'http://releases.ubuntu.com/11.04/ubuntu-11.04-server-amd64.iso',
             :iso_md5 => '355ca2417522cb4a77e0295bf45c5cd5'
            }),
            manifest)
    end

  end

end