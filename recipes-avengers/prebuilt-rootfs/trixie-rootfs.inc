FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
	file://configs/fstab \
	"

do_install() {
	install -d 755 ${D}/root/etc
	install -m 644 ${WORKDIR}/configs/fstab ${D}/root/etc

	if [ "${@bb.utils.contains("MACHINE_FEATURES", "split-home", "1", "0", d)}" = "0" ]; then
		sed -i -e '/LABEL=home/d' ${D}/root/etc/fstab
	fi

	if [ "${@bb.utils.contains("MACHINE_FEATURES", "overlayfs-root", "1", "0", d)}" = "1" ]; then
		sed -i -e '/LABEL=rootfs/d' ${D}/root/etc/fstab
	fi

	( cd ${D}/root ; tar -cvJf ../configs.tar.xz * )
	rm -rf ${D}/root
}

do_package_qa[noexec] = "1"

FILES:${PN} += "/configs.tar.xz"
