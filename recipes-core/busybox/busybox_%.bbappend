FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://ntpd.cfg"
BUSYBOX_CFG_EXTRA += "ntpd.cfg"
