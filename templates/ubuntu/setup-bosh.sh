#!/bin/bash

source _variables.sh

### stage bosh_debs
apt-get -y -qq --force-yes install scsitools mg htop module-assistant debhelper runit
# `rescan-scsi-bus` doesn't have the `.sh` suffix on Ubuntu Precise
pushd /sbin
    if [ ! -f rescan-scsi-bus.sh ]
    then
      ln -s rescan-scsi-bus rescan-scsi-bus.sh
    fi
popd