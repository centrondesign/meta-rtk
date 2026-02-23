#!/bin/bash

debootstrap_rootfs() {
    sudo debootstrap \
        --arch=arm64 \
        trixie \
        arm64-rootfs \
        http://deb.debian.org/debian
}

chroot_fs() {
    sudo mount --bind /dev arm64-rootfs/dev
    sudo mount --bind /dev/pts arm64-rootfs/dev/pts
    sudo mount --bind /proc arm64-rootfs/proc
    sudo mount --bind /sys arm64-rootfs/sys

    cat > arm64-rootfs/tmp/post_debootstrap <<EOF
export LANG=C
export LC_ALL=C

dpkg --configure -a

apt update

apt install -y sudo nano net-tools locales tzdata ca-certificates systemd-sysv
dpkg-reconfigure locales
dpkg-reconfigure tzdata

apt install -y dbus wpasupplicant network-manager
sed -i -e '/managed=false/s/managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf

echo "localhost" > /etc/hostname

sed -i -e '/root/s/:[^:]*:/::/' /etc/shadow

useradd -d /home/debian -m -g users -s /bin/bash -G sudo,audio,video,render debian
sed -i -e '/debian/s/:[^:]*:/::/' /etc/shadow
EOF
    chmod +x arm64-rootfs/tmp/post_debootstrap
    sudo chroot arm64-rootfs /bin/bash -c /tmp/post_debootstrap
    rm -f arm64-rootfs/tmp/post_debootstrap

    sudo umount arm64-rootfs/sys
    sudo umount arm64-rootfs/proc
    sudo umount arm64-rootfs/dev/pts
    sudo umount arm64-rootfs/dev
}

generate_tarball() {
    ( cd arm64-rootfs ; sudo tar Jcf ../trixie-rootfs.tar.xz * )
    sudo chown $USER:$USER trixie-rootfs.tar.xz
}

debootstrap_rootfs
chroot_fs
generate_tarball
