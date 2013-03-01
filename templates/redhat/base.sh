#!/bin/bash

set -x

source _variables.sh

cat > /etc/yum.repos.d/puppetlabs.repo << EOM
[puppetlabs]
name=puppetlabs
baseurl=http://yum.puppetlabs.com/el/6/products/\$basearch
enabled=0
gpgcheck=0
EOM
 
cat > /etc/yum.repos.d/epel.repo << EOM
[epel]
name=epel
baseurl=http://download.fedoraproject.org/pub/epel/6/\$basearch
enabled=0
gpgcheck=0
EOM
 
cat > /etc/yum.repos.d/cfengine.repo << EOM
[cfengine]
name=cfengine
baseurl=http://cfengine.com/pub/yum/
enabled=0
gpgcheck=0
EOM

rpm -U --nosignature http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

# Base install
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# system update
yum -y update
yum -y groupinstall "Development Tools"
yum -y install sudo gcc make gcc-c++ kernel-devel-`uname -r` zlib-devel openssl-devel \
readline-devel sqlite-devel perl wget dkms curl ntp crontabs sysstat pam-devel
yum -y install libxslt-devel libyaml-devel libxml2-devel gdbm-devel libffi-devel zlib-devel \
openssl-devel libyaml-devel readline-devel curl-devel openssl-devel pcre-devel git postgresql-devel