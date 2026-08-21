#!/bin/bash
set -e

# Keyboard layout to bake into the image (e.g. us, de, fr, gb, es).
# Override at build time, e.g.: KBD_LAYOUT=de ./trixie-rootfs.sh
KBD_LAYOUT="${KBD_LAYOUT:-us}"
KBD_MODEL="${KBD_MODEL:-pc105}"
KBD_VARIANT="${KBD_VARIANT:-}"
KBD_OPTIONS="${KBD_OPTIONS:-}"

# Default system locale to bake into the image (must be a UTF-8 locale name).
# Override at build time, e.g.: LOCALE_LANG=de_DE.UTF-8 ./trixie-rootfs.sh
LOCALE_LANG="${LOCALE_LANG:-en_US.UTF-8}"
LOCALE_CHARSET="${LOCALE_CHARSET:-UTF-8}"

# Default timezone to bake into the image (e.g. Asia/Taipei, UTC, Europe/Berlin).
# Override at build time, e.g.: TIMEZONE=UTC ./trixie-rootfs.sh
TIMEZONE="${TIMEZONE:-Asia/Taipei}"

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
set -e
export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

dpkg --configure -a

apt update

# Preseed keyboard layout so keyboard-configuration/console-setup install
# non-interactively (no debconf prompt during the build), and write the file
# that Xorg/localed actually read.
debconf-set-selections <<SEL
keyboard-configuration keyboard-configuration/xkb-keymap select $KBD_LAYOUT
keyboard-configuration keyboard-configuration/layoutcode string $KBD_LAYOUT
keyboard-configuration keyboard-configuration/modelcode string $KBD_MODEL
keyboard-configuration keyboard-configuration/variantcode string $KBD_VARIANT
keyboard-configuration keyboard-configuration/optionscode string $KBD_OPTIONS
SEL

cat > /etc/default/keyboard <<KBD
XKBMODEL="$KBD_MODEL"
XKBLAYOUT="$KBD_LAYOUT"
XKBVARIANT="$KBD_VARIANT"
XKBOPTIONS="$KBD_OPTIONS"
BACKSPACE="guess"
KBD

apt install -y sudo nano net-tools locales tzdata ca-certificates systemd-sysv
apt install -y gpiod i2c-tools usbutils pciutils

# Generate and set the default system locale non-interactively.
sed -i -e "s/^# *${LOCALE_LANG} ${LOCALE_CHARSET}\$/${LOCALE_LANG} ${LOCALE_CHARSET}/" /etc/locale.gen
grep -qxF "${LOCALE_LANG} ${LOCALE_CHARSET}" /etc/locale.gen || echo "${LOCALE_LANG} ${LOCALE_CHARSET}" >> /etc/locale.gen
locale-gen
update-locale LANG=${LOCALE_LANG}

# Set the default timezone non-interactively.
echo "${TIMEZONE}" > /etc/timezone
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

apt install -y dbus wpasupplicant network-manager systemd-timesyncd
sed -i -e '/managed=false/s/managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf

echo "localhost" > /etc/hostname

sed -i -e '/root/s/:[^:]*:/::/' /etc/shadow

if ! id debian >/dev/null 2>&1; then
    useradd -d /home/debian -m -g users -s /bin/bash -G sudo,audio,video,render debian
fi
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

    cp libgl1-mesa-dri_25.0.7-2+deb13u1_arm64.deb arm64-rootfs/tmp
    cat > arm64-rootfs/tmp/post_chroot_script <<EOF
set -e
export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

apt install -y xserver-xorg accountsservice lightdm labwc
sed -i -e 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-gtk-greeter/' /etc/lightdm/lightdm.conf
apt install -y xfce4 xfce4-goodies network-manager-gnome
apt install -y blueman
apt install -y gstreamer1.0-plugins-bad gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-gl
apt install -y v4l-utils
apt install -y gvfs gvfs-backends gvfs-fuse
apt install -y ffmpeg
apt install -y autorandr wlr-randr
apt install -y firefox-esr

dpkg -i /tmp/libgl1-mesa-dri_25.0.7-2+deb13u1_arm64.deb
rm -f /tmp/libgl1-mesa-dri_25.0.7-2+deb13u1_arm64.deb
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
