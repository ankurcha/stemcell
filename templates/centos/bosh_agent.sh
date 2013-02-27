#!/bin/bash

source _variables.sh

mkdir -p /tmp/bosh_agent

pushd /tmp/bosh_agent
    cp $SRC_DIR/_bosh_agent.tar /tmp/bosh_agent
    tar -xvf _bosh_agent.tar
    $bosh_dir/bin/gem install *.gem --force --no-ri --no-rdoc
    chmod +x $bosh_dir/bin/bosh_agent

    # configure bosh agent
    mkdir -p /etc/sv/agent/log
    echo '#!/bin/bash
    export PATH=/var/vcap/bosh/bin:$PATH
    exec 2>&1
    exec /var/vcap/bosh/bin/bosh_agent --configure --infrastructure=`cat /etc/infrastructure`
    ' > /etc/sv/agent/run

    echo '#!/bin/bash
    svlogd -tt /var/vcap/bosh/log
    ' > /etc/sv/agent/log/run

    # runit
    chmod +x /etc/sv/agent/run /etc/sv/agent/log/run

    ln -s /etc/sv/agent /etc/service/agent

    cp $SRC_DIR/_empty_state.yml $bosh_dir/state.yml

    # The bosh agent installs a config that rotates on size
    mv /etc/cron.daily/logrotate /etc/cron.hourly/logrotate

popd
