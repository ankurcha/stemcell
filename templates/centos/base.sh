#!/bin/bash

set -x

source _variables.sh

# Base install
rpm -U --nosignature http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -U --nosignature http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

#yum -y groupinstall "Development Tools"
yum -y install sudo gcc make gcc-c++ kernel-devel-`uname -r` zlib-devel openssl-devel \
readline-devel sqlite-devel perl wget dkms curl ntp crontabs sysstat eject dash
yum -y install libxslt-devel libyaml-devel libxml2-devel gdbm-devel libffi-devel zlib-devel \
openssl-devel libyaml-devel readline-devel curl-devel openssl-devel pcre-devel git postgresql-devel

/usr/sbin/groupadd vcap
/usr/sbin/useradd vcap -g vcap -G wheel
echo "c1oudc0w" | passwd --stdin vcap
echo "vcap        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/vcap
chmod 0440 /etc/sudoers.d/vcap
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers