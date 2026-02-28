DESCRIPTION = "Generate pv from pv recipe for rescue rootfs"
SUMMARY = "Terminal-based tool for monitoring the progress of data through a pipeline"
HOMEPAGE = "http://www.ivarch.com/programs/pv.shtml"

LICENSE = "Artistic-2.0"
LIC_FILES_CHKSUM = "file://doc/COPYING;md5=9c50db2589ee3ef10a9b7b2e50ce1d02"

SRC_URI = "https://www.ivarch.com/programs/sources/pv-1.6.20.tar.bz2 \
           file://0001-pv-display-handle-error-of-tcgetpgrp-in-pv_in_foregr.patch \
"
SRC_URI[sha256sum] = "e831951eff0718fba9b1ef286128773b9d0e723e1fbfae88d5a3188814fdc603"

S = "${WORKDIR}/pv-1.6.20"

UPSTREAM_CHECK_URI = "http://www.ivarch.com/programs/pv.shtml"
UPSTREAM_CHECK_REGEX = "pv-(?P<pver>\d+(\.\d+)+).tar.bz2"

inherit autotools

LDEMULATION:mipsarchn32 = "${@bb.utils.contains('TUNE_FEATURES', 'bigendian', 'elf32btsmipn32', 'elf32ltsmipn32', d)}"
export LDEMULATION

LDFLAGS:append = " -static"
EXTRA_OECONF:remove = "--disable-static"

do_install() {
	install -d ${D}${base_sbindir}
	${STRIP} ${B}/pv
}

inherit deploy nopackages

do_deploy() {
	install -d ${DEPLOYDIR}/staging
	install -m 0755 ${B}/pv ${DEPLOYDIR}/staging/pv
}

addtask deploy after do_install
