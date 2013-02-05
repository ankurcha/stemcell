#!/bin/bash

### stage system_open_vm_tools

cat > /etc/yum.repos.d/vmware-tools.repo << EOM
[vmware-tools]
name=VMware Tools
baseurl=http://packages.vmware.com/tools/esx/5.0/rhel6/x86_64
enabled=1
gpgcheck=1
EOM

rpm --import http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub
rpm --import http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub

yum -y install vmware-tools-esx-kmods-`uname -r` vmware-tools-esx