#!/bin/bash

set -x

source _variables.sh

yum -y erase gtk2 libX11 hicolor-icon-theme avahi freetype bitstream-vera-fonts
yum -y clean all

# install runonce
mkdir -p /etc/local/runonce.d/ran
cp $SRC_DIR/_runonce /usr/local/bin/runonce
chmod +x /usr/local/bin/runonce

sed -i -e 's/^\(HWADDR=.*\)$//g' /etc/sysconfig/network-scripts/ifcfg-eth*
rm /etc/udev/rules.d/70-persistent-net.rules
# Do some firstboot clean up
# Regenerate ssh keys
/usr/local/bin/runonce "rm -f /etc/ssh/ssh_host_*"
/usr/local/bin/runonce "ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''"
/usr/local/bin/runonce "ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''"

# Clean out all the scripts
rm -f _60-bosh-sysctl.conf _monitrc _ntpdate _sysstat _empty_state.yml _variables.sh _helpers.sh _bosh_agent.tar _runonce
rm -f base.sh sudo.sh setup-bosh.sh monit.sh ruby.sh bosh_agent.sh vmware-tools.sh harden.sh timestamp.sh postinstall.sh cleanup.sh zerodisk.sh
rm -f *.iso *.gem
