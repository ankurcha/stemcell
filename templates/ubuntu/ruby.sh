#!/bin/bash

source _variables.sh

### stage bosh_ruby
apt-get -y --force-yes install gcc g++ build-essential libssl-dev libreadline5-dev zlib1g-dev linux-headers-generic libsqlite3-dev libxslt-dev libxml2-dev imagemagick libmysqlclient-dev libmagick9-dev git-core mysql-server wkhtmltopdf git

# install ruby
pushd /tmp
    [ ! -f "ruby-1.9.3-p374.tar.gz" ] && wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p374.tar.gz
	tar zxf ruby-1.9.3-p374.tar.gz
	cd ruby-1.9.3-p374
	./configure --prefix=$bosh_dir --disable-install-doc && make && make install

	# Install rubygems
	cd ..
	[ ! -f "rubygems-1.8.24.tgz" ] && wget http://production.cf.rubygems.org/rubygems/rubygems-1.8.24.tgz
	tar zxf rubygems-1.8.24.tgz
	cd rubygems-1.8.24
	$bosh_dir/bin/ruby setup.rb --no-format-executable
popd

echo "PATH=$PATH:$bosh_dir/bin" > /etc/environment
source /etc/environment

$bosh_dir/bin/gem update --system --no-ri --no-rdoc
mkdir -p $bosh_dir/etc
echo "gem: --no-rdoc --no-ri" >> $bosh_dir/etc/gemrc

#Install gems
$bosh_dir/bin/gem install bundler --no-ri --no-rdoc
