SUMMARY = "Device tree overlays and config.txt for the FAT boot partition"
DESCRIPTION = "Compiles .dts overlay sources into .dtbo and deploys them, \
together with a config.txt, onto the boot partition.  u-boot reads config.txt \
at boot time and applies the overlays listed there to the base DTB."
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

inherit deploy nopackages

DEPENDS = "dtc-native"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Space separated list of overlay basenames, set per machine.  Each entry
# <name> is compiled from <name>.dts into overlays/<name>.dtbo.
DT_OVERLAYS ?= ""

# The base DTB u-boot loads before applying any overlay.  Derived from the
# first KERNEL_DEVICETREE entry, e.g. realtek/rtd1619b-ct1833.dtb.
DT_BASE ?= "${@os.path.basename((d.getVar('KERNEL_DEVICETREE') or '').split()[0]) if (d.getVar('KERNEL_DEVICETREE') or '').split() else ''}"

SRC_URI = "file://config.txt.in"
SRC_URI += "${@' '.join(['file://%s.dts' % o for o in (d.getVar('DT_OVERLAYS') or '').split()])}"

S = "${WORKDIR}"
B = "${WORKDIR}/build"

# overlays and the base DTB name are machine specific
PACKAGE_ARCH = "${MACHINE_ARCH}"

do_compile() {
	install -d ${B}

	if [ -n "${DT_OVERLAYS}" ]; then
		for o in ${DT_OVERLAYS}; do
			dtc -@ -H epapr -I dts -O dtb \
				-o ${B}/${o}.dtbo ${S}/${o}.dts
		done
	fi

	if [ -z "${DT_BASE}" ]; then
		bbfatal "DT_BASE is empty - KERNEL_DEVICETREE is not set for ${MACHINE}"
	fi

	sed -e "s|@DT_BASE@|${DT_BASE}|g" \
	    -e "s|@MACHINE@|${MACHINE}|g" \
	    ${S}/config.txt.in > ${B}/config.txt
}

do_deploy() {
	install -d ${DEPLOYDIR}/overlays

	if [ -n "${DT_OVERLAYS}" ]; then
		for o in ${DT_OVERLAYS}; do
			install -m 0644 ${B}/${o}.dtbo ${DEPLOYDIR}/overlays/
		done
	fi

	install -m 0644 ${B}/config.txt ${DEPLOYDIR}/config.txt
}

addtask deploy after do_compile before do_build
