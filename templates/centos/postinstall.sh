#!/bin/bash

#import helpers scripts
source _variables.sh

### stage bosh_sysstat
cp $SRC_DIR/_sysstat /etc/default/sysstat

### stage bosh_sysctl
[ ! -d /etc/sysctl.d ] && mkdir -p /etc/sysctl.d
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

### stage system_parameters
echo -n $infrastructure > /etc/infrastructure

# Create list of installed packages -- legal requirement
yum list installed > $bosh_dir/stemcell_yum_list_installed.out
