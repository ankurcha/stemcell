#!/bin/bash
set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables
set -x # enable verbose logging

SRC_DIR=`pwd`

apt_get -y install console-data dnsmasq nfs-kernel-server git-core

micro_src=/tmp/micro
micro_dest=/var/vcap/micro
shared_dir=/var/vcap/shared
mkdir -p ${micro_src}
mkdir -p ${shared_dir}

pushd ${micro_src}
    cp ${SRC_DIR}/_micro.tgz ${micro_src}
    tar -xzvf _micro.tgz
    rm _micro.tgz
popd

mkdir -p ${micro_dest}
cp --archive --recursive ${micro_src}/micro/* ${micro_dest}
cp --archive ${micro_src}/micro/mcf-api.conf /etc/init
cp --archive ${SRC_DIR}/_console.sh /etc/init.d/console.sh
cp --archive ${SRC_DIR}/_settings.json /var/vcap/bosh/settings.json
cp --archive ${SRC_DIR}/_tty1.conf /etc/init/tty1.conf
cp ${SRC_DIR}/_extra.conf /etc/dnsmasq.d/extra.conf

# Configure MOTD
rm /etc/update-motd.d/*
cp ${SRC_DIR}/_00-mcf /etc/update-motd.d/00-mcf
cp ${SRC_DIR}/_10-legal /etc/update-motd.d/01-legal
chmod 755 /etc/update-motd.d/*

# Prevent delays in offline mode.
echo 'UseDNS no' >> /etc/ssh/sshd_config
# Listen to IPv4 only.
echo 'ListenAddress 0.0.0.0' >> /etc/ssh/sshd_config
# Start in offline mode
touch /var/vcap/micro/offline

chown vcap:vcap ${micro_dest}
chmod 755 ${micro_dest}

chmod 755 /etc/init.d/console.sh
ln -s /etc/init.d/console.sh /etc/rc2.d/S10console

chown vcap:vcap ${shared_dir}
chmod 700 ${shared_dir}

pushd ${micro_dest}
    /var/vcap/bosh/bin/bundle install --path /var/vcap/bosh/gems --without test
    mkdir /cfsnapshot
    chmod 777 /cfsnapshot
    echo '/cfsnapshot 127.0.0.1(rw,sync)' >> /etc/exports
popd