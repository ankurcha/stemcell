Veewee::Definition.declare({
                               :cpu_count => '1', :memory_size => '512',
                               :disk_size => '10140', :disk_format => 'VDI', :hostiocache => 'off',
                               :os_type_id => 'Ubuntu_64',
                               :iso_file => "ubuntu-11.04-server-amd64.iso",
                               :iso_src => "http://releases.ubuntu.com/11.04/ubuntu-11.04-server-amd64.iso",
                               :iso_md5 => "355ca2417522cb4a77e0295bf45c5cd5",
                               :iso_download_timeout => "1000",
                               :boot_wait => "5", :boot_cmd_sequence => [
        '<Esc><Esc><Enter>',
        '/install/vmlinuz ',
        'initrd=/install/initrd.gz ',
        'noapic ',
        'fb=false ', # don't bother using a framebuffer
        'locale=en_US ', # Start installer in English
        'console-setup/ask_detect=false ', # Don't ask to detect keyboard
        'keyboard-configuration/layout=USA ', # set it to US qwerty
        'keyboard-configuration/variant=USA ',
        'hostname=%NAME% ', # Set the hostname
        'preseed/url=http://%IP%:%PORT%/preseed.cfg ', # Fetch the rest from here
        'auto ',
        'debconf/frontend=noninteractive ',
        'debian-installer=en_US ',
        'kbd-chooser/method=us ',
        '-- <Enter>'
    ],

                               :kickstart_port => "7122", :kickstart_timeout => "10000", :kickstart_file => "preseed.cfg",
                               :ssh_login_timeout => "10000", :ssh_user => "vcap", :ssh_password => "c1oudc0w", :ssh_key => "",
                               :ssh_host_port => "7222", :ssh_guest_port => "22",
                               :sudo_cmd => "echo '%p'|sudo -S /bin/bash '%f'",
                               :shutdown_cmd => "shutdown -P now",
                               :postinstall_files => [
                                   # Files with a leading _ are not executed
                                   "_60-bosh-sysctl.conf",
                                   "_monitrc",
                                   "_ntpdate",
                                   "_sysstat",
                                   "_empty_state.yml",
                                   "_variables.sh",
                                   "_helpers.sh",
                                   "_bosh_agent.gem",
                                   # The following scripts are run on the target vm one by one
                                   "timestamp.sh",
                                   "apt-upgrade.sh",
                                   "sudo.sh",
                                   "setup-bosh.sh",
                                   "base-stemcell.sh",
                                   "monit.sh",
                                   "ruby.sh",
                                   "bosh_agent.sh",
                                   "vmware-tools.sh",
                                   "network-cleanup.sh",
                                   "zero-disk.sh",
                                   "harden.sh",
                                   "postinstall.sh",
                               ],
                               :postinstall_timeout => "10000"
                           })
