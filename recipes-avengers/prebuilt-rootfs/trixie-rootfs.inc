FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
	file://trixie/ \
	"

do_install() {
	cp -a ${WORKDIR}/trixie/. ${D}/root
	chmod g-w `find ${D}/root -type d`
	chmod g-w `find ${D}/root -type f`

	if [ "${@bb.utils.contains("MACHINE_FEATURES", "split-home", "1", "0", d)}" = "0" ]; then
		sed -i -e '/LABEL=home/d' ${D}/root/etc/fstab
	fi

	if [ "${@bb.utils.contains("MACHINE_FEATURES", "overlayfs-root", "1", "0", d)}" = "1" ]; then
		sed -i -e '/LABEL=rootfs/d' ${D}/root/etc/fstab
	fi

	( cd ${D}/root ; tar --owner=0 --group=0 -cvJf ../configs.tar.xz * )
	rm -rf ${D}/root
}

do_package_qa[noexec] = "1"

FILES:${PN} += "/configs.tar.xz"
