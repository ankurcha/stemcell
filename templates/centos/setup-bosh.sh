#!/bin/bash

source _variables.sh

yum -y install glibc-static sg3_utils

pushd /usr/bin
    if [ ! -f rescan-scsi-bus.sh ]
    then
      ln -s rescan-scsi-bus rescan-scsi-bus.sh
    fi
popd

pushd /tmp
	yum -y install git rpm-build rpmdevtools gcc glibc-static make
	git clone https://github.com/imeyer/runit-rpm.git
	cd runit-rpm
	./build.sh
	rpm -i ~/rpmbuild/RPMS/*/*.rpm
popd