FILESEXTRAPATHS:prepend := "${THISDIR}/samba:"

SRC_URI:append = " \
		file://901-nas-reverse-sendfile-syscall.patch \
		file://902-io-way-auto-selection.patch \
		"
