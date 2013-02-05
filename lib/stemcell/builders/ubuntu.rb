module Bosh::Agent::StemCell

  # This is concrete Stemcell builder for creating a Ubuntu stemcell
  # It creates a Ubuntu 11.04. The options passed are merged with
  # {
  #   :type => 'ubuntu',
  #   :iso => 'http://releases.ubuntu.com/11.04/ubuntu-11.04-server-amd64.iso',
  #   :iso_md5 => '355ca2417522cb4a77e0295bf45c5cd5',
  #   :iso_filename => 'ubuntu-11.04-server-amd64.iso'
  # }
  #
  # The manifest is passed with the following additional valued
  # {
  #   :cloud_properties => {
  #     :root_device_name => '/dev/sda1'
  #   }
  # }
  class UbuntuBuilder < BaseBuilder

    def package_stemcell
      # unbox the exported thing
      Dir.chdir(@prefix) do
	unless system "tar -xzf #@name.box"
          raise "Unable to unpack exported .box file"
        end
      end

      # tar up the vmdk, ovf files to 'image'
      image_path = File.expand_path "image", @prefix
      unless system "tar -cvf #{image_path} *.vmdk *.ovf"
        raise "Unable to create image tar from ovf and vmdk"
      end

      # Create the stemcell manifest
      stemcell_mf_path = File.expand_path "stemcell.MF", @prefix
      File.open(stemcell_mf_path, "w") do |f|
        f.write(@manifest.to_yaml)
      end

      # TODO: deal with package list
      legal_package_list = File.expand_path "stemcell_dpkg_l.txt"

      package_files image_path, stemcell_mf_path
    end

    def initialize(opts={}, manifest={:cloud_properties => {:root_device_name => '/dev/sda1'}})
      super(
	  opts.deep_merge(
	      {
		  :type => 'ubuntu',
		  :iso => 'http://releases.ubuntu.com/11.04/ubuntu-11.04-server-amd64.iso',
		  :iso_filename => 'ubuntu-11.04-server-amd64.iso', :iso_md5 => '355ca2417522cb4a77e0295bf45c5cd5'
	      }),
	  manifest)
    end

  end

end
