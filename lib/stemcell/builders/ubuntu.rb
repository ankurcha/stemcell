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
  # The manifest is passed with the following additional merged values
  # {
  #   :cloud_properties => {
  #     :root_device_name => '/dev/sda1'
  #   }
  # }
  class UbuntuBuilder < BaseBuilder

    def initialize(opts={}, manifest={})
      super(
          opts.deep_merge(
              {
                  :type => 'ubuntu',
                  :iso => 'http://releases.ubuntu.com/11.04/ubuntu-11.04-server-amd64.iso',
                  :iso_filename => 'ubuntu-11.04-server-amd64.iso', :iso_md5 => '355ca2417522cb4a77e0295bf45c5cd5'
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
