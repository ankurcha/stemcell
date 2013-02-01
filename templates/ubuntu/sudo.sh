#!/bin/bash

cp /etc/sudoers /etc/sudoers.orig
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers
cp -p /etc/sudoers /etc/sudoers.save
echo '#includedir /etc/sudoers.d' >> /etc/sudoers
visudo -c
if [ $? -ne 0 ]; then
  echo "ERROR: bad sudoers file"
  exit 1
fi
rm /etc/sudoers.save
