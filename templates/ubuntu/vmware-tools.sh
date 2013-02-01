#!/bin/bash

### stage system_open_vm_tools
### -> vmware-tools to be fetched from the apt repo <find this repo>
# open-vm-tools needed to be backported to work with the 2.6.38 kernel
# https://bugs.launchpad.net/ubuntu/+source/open-vm-tools/+bug/746152
echo "deb http://packages.vmware.com/tools/esx/5.0/ubuntu natty main" >> /etc/apt/sources.list
wget -q http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub -O- | sudo apt-key add -
wget -q http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub -O- | sudo apt-key add -

apt-get update

apt-get -y -qq --force-yes install vmware-tools-vmxnet3-modules-source vmware-tools-vmxnet3-common \
vmware-tools-pvscsi-modules-source vmware-tools-pvscsi-common vmware-tools-vmmemctl-modules-source \
vmware-tools-vmmemctl-common vmware-tools-vmci-modules-source vmware-tools-vmci-common vmware-tools-esx-nox \
vmware-tools-foundation debhelper

module-assistant prepare

for i in vmware-tools-vmxnet3-modules-source vmware-tools-pvscsi-modules-source vmware-tools-vmmemctl-modules-source vmware-tools-vmci-modules-source; do module-assistant build $i; module-assistant install $i; done
