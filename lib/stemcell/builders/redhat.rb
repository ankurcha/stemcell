module Bosh::Agent::StemCell

  class RedhatBuilder < BaseBuilder

    def type
      "redhat"
    end

    def init_default_iso
      @iso = "http://rhnproxy1.uvm.edu/pub/redhat/rhel6-x86_64/isos/rhel-server-6.3-x86_64-dvd.iso"
      @iso_md5 = "d717af33dd258945e6304f9955487017"
      @iso_filename = "rhel-server-6.3-x86_64-dvd.iso"
    end

  end
end
