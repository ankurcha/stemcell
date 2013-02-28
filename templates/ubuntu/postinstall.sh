#!/bin/bash
set -x

#import helpers scripts
source _variables.sh

### stage bosh_sysstat
cp $SRC_DIR/_sysstat /etc/default/sysstat

### stage bosh_sysctl
cp $SRC_DIR/_60-bosh-sysctl.conf /etc/sysctl.d/60-bosh-sysctl.conf
chmod 0644 /etc/sysctl.d/60-bosh-sysctl.conf

### stage bosh_ntpdate
# setup crontab for root to use ntpdate every 15 minutes
mkdir -p $bosh_dir/log
cp $SRC_DIR/_ntpdate $bosh_dir/bin/ntpdate
chmod 0755 $bosh_dir/bin/ntpdate
echo "0,15,30,45 * * * * ${bosh_dir}/bin/ntpdate" > /tmp/ntpdate.cron
crontab -u root /tmp/ntpdate.cron
rm /tmp/ntpdate.cron

### stage micro_bosh ???

### stage system_parameters
echo -n $system_parameters_infrastructure > /etc/infrastructure


### stage bosh_dpkg_list ??? How do we get back a list of things
# Create list of installed packages -- legal requirement
dpkg -l > $bosh_dir/stemcell_dpkg_l.out

# Clean out all the scripts
rm -f _60-bosh-sysctl.conf _monitrc _ntpdate _sysstat _empty_state.yml _variables.sh _helpers.sh _bosh_agent.tar
rm -f timestamp.sh apt-upgrade.sh sudo.sh setup-bosh.sh base-stemcell.sh monit.sh ruby.sh bosh_agent.sh vmware-tools.sh network-cleanup.sh
rm -f zero-disk.sh harden.sh postinstall.sh *.iso *.gem

# install runonce
mkdir -p /etc/local/runonce.d/ran
cp $SRC_DIR/_runonce /usr/local/bin/runonce
chmod +x /usr/local/bin/runonce

# Do some firstboot clean up
# Regenerate ssh keys
/usr/local/bin/runonce "rm -f /etc/ssh/ssh_host_*"
/usr/local/bin/runonce "dpkg-reconfigure -fnoninteractive -pcritical openssh-server"

# Clean up cdrom rules
sed -i -e 's/cdrom1/cdrom/g' /etc/udev/rules.d/70-persistent-cd.rules
sed -i -e 's/dvd1/dvd/g' /etc/udev/rules.d/70-persistent-cd.rules
