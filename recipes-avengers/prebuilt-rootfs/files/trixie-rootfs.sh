#!/bin/bash

debootstrap_rootfs() {
    sudo debootstrap \
        --arch=arm64 \
        --include=ca-certificates,tzdata,locales,systemd-sysv,net-tools,command-not-found,sudo,nano,dbus,wpasupplicant,network-manager \
        trixie \
        arm64-rootfs \
        http://deb.debian.org/debian
}

chroot_fs() {
    sudo chroot arm64-rootfs /bin/sh<<EOF
export LANG=C

echo "localhost" > /etc/hostname

sed '/root/s/:[^:]*:/::/' /etc/shadow > /etc/shadow-
cp /etc/shadow- /etc/shadow

useradd -d /home/debian -m -g users -s /bin/bash -G sudo,audio,video,render debian
sed '/debian/s/:[^:]*:/::/' /etc/shadow > /etc/shadow-
cp /etc/shadow- /etc/shadow
EOF
}

generate_tarball() {
    ( cd arm64-rootfs ; sudo tar Jcf ../trixie-rootfs.tar.xz * )
    sudo chown $USER:$USER trixie-rootfs.tar.xz
}

debootstrap_rootfs
chroot_fs
generate_tarball
