#!/bin/bash

set -x

source _variables.sh

yum -y erase gtk2 libX11 hicolor-icon-theme avahi freetype bitstream-vera-fonts
yum -y clean all

# Clean out all the scripts
rm -f _60-bosh-sysctl.conf _monitrc _ntpdate _sysstat _empty_state.yml _variables.sh _helpers.sh _bosh_agent.tar
rm -f base.sh sudo.sh setup-bosh.sh monit.sh ruby.sh bosh_agent.sh vmware-tools.sh harden.sh timestamp.sh postinstall.sh cleanup.sh zerodisk.sh
rm -f *.iso *.gem

# Clean out ssh host keys
rm -f /etc/ssh/ssh_host_*

