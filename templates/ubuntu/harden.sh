#!/bin/bash
set -x

### stage bosh_harden
# remove setuid binaries - except su/sudo (sudoedit is hardlinked)
find / -xdev -perm +6000 -a -type f \
  -a -not \( -name sudo -o -name su -o -name sudoedit \) \
  -exec chmod ug-s {} \;

