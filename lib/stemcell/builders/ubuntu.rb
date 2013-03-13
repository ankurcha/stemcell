require 'stemcell/builder'

module Bosh::Agent::StemCell

  # This is concrete Stemcell builder for creating a Ubuntu stemcell
  # It creates a Ubuntu 11.04. The options passed are merged with
  # {
  #   :type => 'ubuntu',
  #   :iso => 'http://releases.ubuntu.com/11.04/ubuntu-11.04-server-amd64.iso',
  #   :iso_md5 => '355ca2417522cb4a77e0295bf45c5cd5',
  #   :iso_filename => 'ubuntu-11.04-server-amd64.iso'
  # }
  class UbuntuBuilder < BaseBuilder

    def type
      "ubuntu"
    end

    def init_default_iso
      @iso = "http://releases.ubuntu.com/11.04/ubuntu-11.04-server-amd64.iso"
      @iso_md5 = "355ca2417522cb4a77e0295bf45c5cd5"
      @iso_filename = "ubuntu-11.04-server-amd64.iso"
    end

    def pre_shutdown_hook
      super()
      download_file("/var/vcap/bosh/stemcell_dpkg_l.out")
    end

    def stemcell_files
      File.join(@prefix, "stemcell_dpkg_l.out")
    end

  end

end
