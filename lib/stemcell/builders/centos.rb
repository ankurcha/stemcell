module Bosh::Agent::StemCell

  class CentosBuilder < BaseBuilder

    def package_stemcell
      # unbox the exported thing
      image_path = File.expand_path "image", @prefix

      Dir.chdir(@prefix) do

        unless system "tar -xzf #@name.box"
          raise "Unable to unpack exported .box file"
        end

        # tar up the vmdk, ovf files to 'image'
        unless system "tar -czf #{image_path} *.vmdk *.ovf"
          raise "Unable to create image tar from ovf and vmdk"
        end

      end

      # Create the stemcell manifest
      stemcell_mf_path = File.expand_path "stemcell.MF", @prefix
      File.open(stemcell_mf_path, "w") do |f|
        f.write(@manifest.to_yaml)
      end

      package_files image_path, stemcell_mf_path
    end

    def initialize(opts={}, manifest={})
      super(
          opts.deep_merge(
              {
                  :type => 'centos',
                  :iso => 'http://www.mirrorservice.org/sites/mirror.centos.org/6.3/isos/x86_64/CentOS-6.3-x86_64-minimal.iso',
                  :iso_filename => 'CentOS-6.3-x86_64-minimal.iso', :iso_md5 => '087713752fa88c03a5e8471c661ad1a2'
              }),
          manifest.deep_merge(
              {
                  :cloud_properties => {
                      :root_device_name => '/dev/sda1'
                  }
              }
          ))
    end

  end
end
