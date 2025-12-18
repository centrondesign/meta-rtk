FILESEXTRAPATHS:append := ":${THISDIR}/../../vendor/realtek/linux/files-${KMNVER}"
SRC_URI:append = " file://avengers-nas-kmeta;type=kmeta;name=avengers-nas-kmeta;destsuffix=avengers-nas-kmeta"
KERNEL_FEATURES:append: = " ${@bb.utils.contains('MACHINE_FEATURES', 'mali', '', 'features/nas-sf/nas-sf.scc', d)}"
