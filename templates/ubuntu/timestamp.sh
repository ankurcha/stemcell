#!/bin/bash
set -x

source _variables.sh

apt-get -y install ntp

# Synchronize time with pool.ntp.org
ntpdate pool.ntp.org

date > /etc/box_build_time


