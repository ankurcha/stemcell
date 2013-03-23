#!/bin/bash

set -x

source _variables.sh

# install libyaml
pushd /tmp
	[ ! -f "yaml-0.1.4.tar.gz" ] && wget http://pyyaml.org/download/libyaml/yaml-0.1.4.tar.gz
    tar zxf yaml-0.1.4.tar.gz
    cd yaml-0.1.4
    ./configure
    make
    make install
    echo /usr/local/lib >> /etc/ld.so.conf
    ldconfig
popd

# install ruby and rubygems
pushd /tmp
	[ ! -f "ruby-1.9.3-p374.tar.gz" ] && wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p374.tar.gz
    tar zxf ruby-1.9.3-p374.tar.gz
    cd ruby-1.9.3-p374
    ./configure --prefix=$bosh_dir --disable-install-doc
    make
    make install
popd

pushd /tmp
	[ ! -f "rubygems-1.8.24.tgz" ] && wget http://production.cf.rubygems.org/rubygems/rubygems-1.8.24.tgz
	tar zxf rubygems-1.8.24.tgz
	cd rubygems-1.8.24
	$bosh_dir/bin/ruby setup.rb --no-format-executable
popd

export PATH=$PATH:$bosh_dir/bin
$bosh_dir/bin/gem update --system --no-ri --no-rdoc
mkdir -p $bosh_dir/etc
echo "gem: --no-rdoc --no-ri" >> $bosh_dir/etc/gemrc

# Install bundler gem
$bosh_dir/bin/gem install bundler --no-ri --no-rdoc