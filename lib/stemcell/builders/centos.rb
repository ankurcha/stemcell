module Bosh::Agent::StemCell

  # This is concrete Stemcell builder for creating a Centos stemcell
  # It creates a CentOS-6.3. The options passed are merged with
  # {
  #   :type => 'centos',
  #   :iso => 'http://www.mirrorservice.org/sites/mirror.centos.org/6.3/isos/x86_64/CentOS-6.3-x86_64-minimal.iso',
  #   :iso_md5 => '087713752fa88c03a5e8471c661ad1a2',
  #   :iso_filename => 'CentOS-6.3-x86_64-minimal.iso'
  # }
  #
  # The manifest is passed with the following additional merged values
  # {
  #   :cloud_properties => {
  #     :root_device_name => '/dev/sda1'
  #   }
  # }
  class CentosBuilder < BaseBuilder

    def generate_image
      # FIXME: This should be common for all the vmdk based builder
      #        Refactor me later!

      Dir.chdir(@prefix) do
        unless system "tar -xzf #{@name}.box"
          raise "Unable to unpack .box file"
        end

        unless system "tar -czf image *.vmdk *.ovf"
          raise "Unable to create image file from ovf and vmdk"
        end
      end
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
