#!/bin/bash
set -x

source _helpers.sh

PACKAGES="build-essential,libssl-dev,lsof,strace,bind9-host,dnsutils,tcpdump,iputils-arping,curl,wget,libcurl3,bison,libreadline6-dev,libxml2,libxml2-dev,libxslt1.1,libxslt1-dev,zip,unzip,nfs-common,flex,psmisc,iptables,sysstat,rsync,openssh-server,libncurses5-dev,quota,libaio1,gdb,psmisc,dialog"
CHROOT=/tmp/chroot
[ -d $CHROOT ] && rm -rf $CHROOT && mkdir -p $CHROOT

## Check if stemcell_base.tar.gz already exists
[ -f $bosh_app_dir/stemcell_base.tar.gz ] && exit 0

pushd /tmp
    ARCH=$(dpkg --print-architecture)
    debootstrap --make-tarball=debootstrap-squeeze-tarball.tar --arch=$ARCH  --include=$PACKAGES squeeze $CHROOT
    debootstrap --variant=minbase --unpack-tarball=/tmp/debootstrap-squeeze-tarball.tar squeeze $CHROOT
    # Creates a pristine image to be run inside a warden container.
    hostname="ubuntu.defaultdomain ubuntu"
    rm -f $CHROOT/var/lib/apt/lists/{archive,security,lock}*

    # Reconfigure timezone and locale
    echo 'en_US.UTF-8 UTF-8' > $CHROOT/etc/locale.gen
    echo 'UTC' > $CHROOT/etc/timezone
    run_in_chroot $CHROOT "
    dpkg-reconfigure -fnoninteractive libc6
    dpkg-reconfigure -fnoninteractive locales
    dpkg-reconfigure -fnoninteractive tzdata
    "

    # Fix /etc/mtab
    run_in_chroot $CHROOT "ln -s /proc/mounts /etc/mtab"

   # configure the network using the dhcp
    cat <<EOF > $CHROOT/etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

    # set the hostname
    cat <<EOF > $CHROOT/etc/hostname
$hostname
EOF
    # set minimal hosts
    cat <<EOF > $CHROOT/etc/hosts
127.0.0.1   localhost
127.0.1.1   $hostname

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

    # Install Firstboot script
    cat <<EOF > $CHROOT/etc/rc.local
#!/bin/sh -e
#execute firstboot.sh only once
if [ ! -e /root/firstboot_done ]; then
    if [ -e /root/firstboot.sh ]; then
        /root/firstboot.sh
    fi
    touch /root/firstboot_done
fi
exit 0
EOF
    cat <<EOF > $CHROOT/root/firstboot.sh
#!/bin/sh
rm /etc/resolv.conf
touch /etc/resolv.conf
rm /etc/ssh/ssh_host*key*
/etc/init.d/networking restart
dpkg-reconfigure -fnoninteractive -pcritical openssh-server
dpkg-reconfigure -fnoninteractive sysstat
EOF
    chmod 0755 $CHROOT/root/firstboot.sh

    # perform clean up
    run_in_chroot $CHROOT "
apt-get clean
apt-get autoremove
"
    echo "Creating base stemcell archive at $bosh_app_dir/stemcell_base.tar.gz"
    tar -C $CHROOT -czf $bosh_app_dir/stemcell_base.tar.gz .
    chmod 0700 $bosh_app_dir/stemcell_base.tar.gz
popd
