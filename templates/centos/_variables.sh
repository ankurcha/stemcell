#!/bin/bash

bosh_app_dir=/var/vcap
bosh_dir=$bosh_app_dir/bosh
bosh_users_password="c1owdc0w"
system_parameters_infrastructure="vsphere"
SRC_DIR=`pwd`

if [ ! -d "$bosh_dir" ]; then
	# create bosh_dir and add to path
	mkdir -p $bosh_dir
	echo "PATH=$PATH:$bosh_dir/bin
export PATH
" >> /etc/profile

	echo "PATH=$PATH:$bosh_dir/bin
export PATH
" >> /root/.bash_profile

	export PATH=$PATH:$bosh_dir/bin
fi

