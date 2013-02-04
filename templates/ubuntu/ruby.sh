#!/bin/bash

source _variables.sh

### stage bosh_ruby
# install ruby and rubygems
if ! which ruby &> /dev/null; then
	pushd /tmp
    	[ ! -f "ruby-1.9.3-p374.tar.gz" ] && wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p374.tar.gz
    	tar zxf ruby-1.9.3-p374.tar.gz
    	cd ruby-1.9.3-p374
    	./configure --prefix=$bosh_dir --disable-install-doc
    	make && make install
	popd
fi
if ! which gem &> /dev/null; then
	pushd /tmp
	    [ ! -f "rubygems-1.8.24.tgz" ] && wget http://production.cf.rubygems.org/rubygems/rubygems-1.8.24.tgz
	    tar zxf rubygems-1.8.24.tgz
	    cd rubygems-1.8.24
	    $bosh_dir/bin/ruby setup.rb --no-format-executable
	popd
fi
export PATH=$PATH:$bosh_dir/bin
$bosh_dir/bin/gem update --system --no-ri --no-rdoc
mkdir -p $bosh_dir/etc
echo "gem: --no-rdoc --no-ri" >> $bosh_dir/etc/gemrc

#Install gems
$bosh_dir/bin/gem install bundler --no-ri --no-rdoc
