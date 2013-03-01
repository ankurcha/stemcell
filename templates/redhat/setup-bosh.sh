#!/bin/bash

source _variables.sh

yum -y install glibc-static sg3_utils

pushd /usr/bin
    if [ ! -f rescan-scsi-bus.sh ]
    then
      ln -s rescan-scsi-bus rescan-scsi-bus.sh
    fi
popd

mkdir -p /package
chmod 1755 /package

pushd /package
    wget http://cr.yp.to/daemontools/daemontools-0.76.tar.gz
    tar xzvf daemontools-0.76.tar.gz
    rm -f daemontools-0.76.tar.gz
    cd admin/daemontools-0.76/src
    wget http://www.qmailrocks.org/downloads/patches/daemontools-0.76.errno.patch
    patch < daemontools-0.76.errno.patch
    cd ..
    package/install
popd

pushd /package
	wget http://smarden.org/runit/runit-2.1.1.tar.gz
	tar -xzf runit-2.1.1.tar.gz
	rm runit-2.1.1.tar.gz
	cd admin/runit-2.1.1
	package/install
popd