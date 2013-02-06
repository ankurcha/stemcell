#!/bin/bash

source _variables.sh

### stage bosh_monit
mkdir -p $bosh_dir/etc
cp $SRC_DIR/_monitrc $bosh_dir/etc/monitrc
chmod 0700 $bosh_dir/etc/monitrc

pushd /tmp
    [ ! -f "monit-5.5.tar.gz" ] && wget http://mmonit.com/monit/dist/monit-5.5.tar.gz
    tar xzvf monit-5.5.tar.gz
    cd monit-5.5
    ./configure --prefix=$bosh_dir --without-ssl
    make && make install
    # monit refuses to start without an include file present
    mkdir -p $bosh_app_dir/monit
    touch /$bosh_app_dir/monit/empty.monitrc
popd
