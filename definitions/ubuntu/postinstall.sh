#!/bin/bash

#import helpers scripts
source _variables.sh

### stage bosh_sysstat
cp $HOME/_sysstat /etc/default/sysstat

### stage bosh_sysctl
cp $HOME/_60-bosh-sysctl.conf /etc/sysctl.d/60-bosh-sysctl.conf
chmod 0644 /etc/sysctl.d/60-bosh-sysctl.conf

### stage bosh_ntpdate
# setup crontab for root to use ntpdate every 15 minutes
mkdir -p $bosh_dir/log
cp $HOME/_ntpdate $bosh_dir/bin/ntpdate
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
