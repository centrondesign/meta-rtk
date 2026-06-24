KMNVER = "${@d.getVar('PV').split('.')[0]}.${@d.getVar('PV').split('.')[1]}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files-${KMNVER}:"

COMPATIBLE_MACHINE:evb-rtd1635-mini = "prince"
COMPATIBLE_MACHINE:rose-rtd1635 = "prince"
COMPATIBLE_MACHINE:phantom-rtd1625-mini = "kent"
COMPATIBLE_MACHINE:phantom-vcodec-rtd1625 = "kent"
COMPATIBLE_MACHINE:phantom-rtd1625 = "kent"
COMPATIBLE_MACHINE:bleedingedge-rtd1619b-mini = "stark"

KMACHINE:evb-rtd1635-mini = "evb-rtd1635"
KMACHINE:rose-rtd1635 = "evb-rtd1635"
KMACHINE:phantom-rtd1625-mini = "phantom-rtd1625"
KMACHINE:phantom-vcodec-rtd1625 = "phantom-rtd1625"
KMACHINE:phantom-rtd1625 = "phantom-rtd1625"
KMACHINE:bleedingedge-rtd1619b-mini = "bleedingedge-rtd1619b"

SRCREV_machine = "081aa259b8f0252bfc7999b289b79bf129893498"
SRCREV_meta = "7a8d96185b9be165feb974fe6297b518f83b3b9c"
LINUX_VERSION = "6.12.58"

SRC_URI:append = " file://avengers-kmeta;type=kmeta;name=avengers-kmeta;destsuffix=avengers-kmeta"

SRC_URI:append:prince = " file://prince.scc file://prince.cfg"
SRC_URI:append:kent = " file://kent.scc file://kent.cfg"
SRC_URI:append:stark = " file://stark.scc file://stark.cfg"

KERNEL_FEATURES:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'mali', '', 'features/nas/nas.scc', d)}"

V4L2_CFG = "${@bb.utils.contains('DISTRO_FEATURES', 'stateless_v4l2', 'v4l2_stateless.scc', 'v4l2_stateful.scc', d )}"

KERNEL_FEATURES:append = " \
			${@bb.utils.contains('MACHINE_FEATURES', 'drm', 'features/dma-buf/dma-buf.scc', '', d)} \
			${@bb.utils.contains('MACHINE_FEATURES', 'drm', 'features/remoteproc/remoteproc.scc', '', d)} \
			${@bb.utils.contains('MACHINE_FEATURES', 'drm', 'features/rpmsg/rpmsg.scc', '', d)} \
			${@bb.utils.contains('MACHINE_FEATURES', 'drm', 'features/drm/drm.scc', '', d)} \
			${@bb.utils.contains('MACHINE_FEATURES', 'drm', 'features/sound/sound.scc', '', d)} \
			${@bb.utils.contains('MACHINE_FEATURES', 'drm', 'features/media/media.scc', '', d)} \
			${@bb.utils.contains('MACHINE_FEATURES', 'v4l2', 'features/media/v4l2.scc', '', d)} \
			${@bb.utils.contains('MACHINE_FEATURES', 'v4l2', 'features/media/${V4L2_CFG}', '', d)} \
			${@bb.utils.contains('MACHINE_FEATURES', 'dprx', 'features/dprx/dprx.scc', '', d)} \
			${@bb.utils.contains_any('MACHINE_FEATURES', 'vendor-wifi upstream-wifi', 'features/wifi/wifi.scc', '', d)} \
			${@bb.utils.contains('MACHINE_FEATURES', 'upstream-wifi', 'features/wifi/rtw.scc', '', d)} \
			${@bb.utils.contains_any('MACHINE_FEATURES', 'vendor-bt upstream-bt', 'features/bt/bt.scc', '', d)} \
			${@bb.utils.contains('MACHINE_FEATURES', 'upstream-bt', 'features/bt/rtl.scc', '', d)} \
			"

KERNEL_FEATURES:append = "${@bb.utils.contains('MACHINE_FEATURES', 'panfrost', 'features/drm-mesa/mesa.scc', 'features/mali/mali.scc', d)}"
KERNEL_MODULE_AUTOLOAD += " ${@bb.utils.contains('MACHINE_FEATURES', 'drm', 'snd-soc-rtk-hifi snd-soc-rtk-afe rtk_avcpulog', '', d)}"
KERNEL_MODULE_AUTOLOAD += " ${@bb.utils.contains('MACHINE_FEATURES', 'vendor-bt', 'rtk_rfkill', '', d)}"
KERNEL_MODULE_AUTOLOAD += " ${@bb.utils.contains('MACHINE_FEATURES', 'upstream-bt', 'hci_uart', '', d)}"

require linux-avengers.inc
