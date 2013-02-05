#!/bin/bash

set -x

source _variables.sh

# Turn on NTP service
chkconfig ntpd on
# Synchronize time with pool.ntp.org
ntpdate pool.ntp.org
# Start the NTP service
/etc/init.d/ntpd start

# save build time
date > /etc/box_build_time
