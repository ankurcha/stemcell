#!/bin/bash

set -x

source _variables.sh

# Base install
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

cat > /etc/yum.repos.d/epel.repo << EOM
[epel]
name=epel
baseurl=http://download.fedoraproject.org/pub/epel/6/\$basearch
enabled=1
gpgcheck=0
EOM

# system update
yum -y update
yum -y groupinstall "Development Tools"
yum -y install gcc make gcc-c++ kernel-devel-`uname -r` zlib-devel openssl-devel \
readline-devel sqlite-devel perl wget dkms curl ntp crontabs sysstat
yum -y install libxslt-devel libyaml-devel libxml2-devel gdbm-devel libffi-devel zlib-devel \
openssl-devel libyaml-devel readline-devel curl-devel openssl-devel pcre-devel git postgresql-devel