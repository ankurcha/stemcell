#!/bin/bash

set -x

source _variables.sh

# Base install
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
sudo rpm -Uvh remi-release-6*.rpm epel-release-6*.rpm

# system update
yum -y update
yum -y groupinstall "Development Tools"
yum -y install gcc make gcc-c++ kernel-devel-`uname -r` zlib-devel openssl-devel \
readline-devel sqlite-devel perl wget dkms curl ntp crontabs sysstat
yum -y install libxslt-devel libyaml-devel libxml2-devel gdbm-devel libffi-devel zlib-devel \
openssl-devel libyaml-devel readline-devel curl-devel openssl-devel pcre-devel git postgresql-devel