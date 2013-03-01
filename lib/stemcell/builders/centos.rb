module Bosh::Agent::StemCell

  # This is concrete Stemcell builder for creating a Centos stemcell
  # It creates a CentOS-6.3. The options passed are merged with
  # {
  #   :type => 'centos',
  #   :iso => 'http://www.mirrorservice.org/sites/mirror.centos.org/6.3/isos/x86_64/CentOS-6.3-x86_64-minimal.iso',
  #   :iso_md5 => '087713752fa88c03a5e8471c661ad1a2',
  #   :iso_filename => 'CentOS-6.3-x86_64-minimal.iso'
  # }
  class CentosBuilder < BaseBuilder

    def type
      "centos"
    end

    def pre_shutdown_hook
      ssh_download_file("/var/vcap/bosh/stemcell_yum_list_installed.out", File.join(@prefix, "stemcell_yum_list_installed.out"))
    end

    def stemcell_files
      File.join(@prefix, "stemcell_yum_list_installed.out")
    end

    def init_default_iso
      @iso = "http://www.mirrorservice.org/sites/mirror.centos.org/6.3/isos/x86_64/CentOS-6.3-x86_64-minimal.iso"
      @iso_md5 = "087713752fa88c03a5e8471c661ad1a2"
      @iso_filename = "CentOS-6.3-x86_64-minimal.iso"
    end

  end
end
