#!/bin/bash

debootstrap_rootfs() {
    sudo debootstrap \
        --arch=arm64 \
        trixie \
        arm64-rootfs \
        http://deb.debian.org/debian
}

mini_setup() {
    sudo mount --bind /dev arm64-rootfs/dev
    sudo mount --bind /dev/pts arm64-rootfs/dev/pts
    sudo mount --bind /proc arm64-rootfs/proc
    sudo mount --bind /sys arm64-rootfs/sys

    cat > arm64-rootfs/tmp/post_chroot_script <<EOF
export LANG=C
export LC_ALL=C

dpkg --configure -a

apt update

apt install -y sudo nano net-tools locales tzdata ca-certificates systemd-sysv
dpkg-reconfigure locales
dpkg-reconfigure tzdata

apt install -y dbus wpasupplicant network-manager systemd-timesyncd snapd
sed -i -e '/managed=false/s/managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf

echo "localhost" > /etc/hostname

sed -i -e '/root/s/:[^:]*:/::/' /etc/shadow

useradd -d /home/debian -m -g users -s /bin/bash -G sudo,audio,video,render debian
sed -i -e '/debian/s/:[^:]*:/::/' /etc/shadow
EOF
    chmod +x arm64-rootfs/tmp/post_chroot_script
    sudo chroot arm64-rootfs /bin/bash -c /tmp/post_chroot_script
    rm -f arm64-rootfs/tmp/post_chroot_script

    sudo umount arm64-rootfs/sys
    sudo umount arm64-rootfs/proc
    sudo umount arm64-rootfs/dev/pts
    sudo umount arm64-rootfs/dev
}

desktop_install() {
    sudo mount --bind /dev arm64-rootfs/dev
    sudo mount --bind /dev/pts arm64-rootfs/dev/pts
    sudo mount --bind /proc arm64-rootfs/proc
    sudo mount --bind /sys arm64-rootfs/sys

    cp libgl1-mesa-dri_25.0.7-2_arm64.deb arm64-rootfs/tmp
    cat > arm64-rootfs/tmp/post_chroot_script <<EOF
apt install -y xserver-xorg accountsservice lightdm labwc
sed -i -e 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-gtk-greeter/' /etc/lightdm/lightdm.conf
apt install -y xfce4 xfce4-goodies network-manager-gnome
apt install -y gstreamer1.0-plugins-bad gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-gl
apt install -y v4l-utils
apt install -y gvfs gvfs-backends gvfs-fuse
apt install -y ffmpeg
snap install firefox

dpkg -i /tmp/libgl1-mesa-dri_25.0.7-2_arm64.deb
rm -f /tmp/libgl1-mesa-dri_25.0.7-2_arm64.deb
EOF
    chmod +x arm64-rootfs/tmp/post_chroot_script
    sudo chroot arm64-rootfs /bin/bash -c /tmp/post_chroot_script
    rm -f arm64-rootfs/tmp/post_chroot_script

    sudo umount arm64-rootfs/sys
    sudo umount arm64-rootfs/proc
    sudo umount arm64-rootfs/dev/pts
    sudo umount arm64-rootfs/dev
}

desktop_config() {
    cat > arm64-rootfs/tmp/post_chroot_script <<EOF
sed -i -e 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-gtk-greeter/' /etc/lightdm/lightdm.conf
EOF
    chmod +x arm64-rootfs/tmp/post_chroot_script
    sudo chroot arm64-rootfs /bin/bash -c /tmp/post_chroot_script
    rm -f arm64-rootfs/tmp/post_chroot_script
}

generate_tarball() {
    ( cd arm64-rootfs ; sudo tar Jcf ../trixie-rootfs.tar.xz * )
    sudo chown $USER:$USER trixie-rootfs.tar.xz
}

debootstrap_rootfs
mini_setup
desktop_install
desktop_config
generate_tarball
