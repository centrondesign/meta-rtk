# Copyright (C) 2024 Realtek Semiconductor Corp.

SUMMARY = "libnpu"
LICENSE = "CLOSED"

inherit bin_package pkgconfig

SRC_URI = "file://${BPN}.tar.xz"
SRCREV = "${AUTOREV}"
include ${BPN}.inc

DEPENDS = "nnstreamer"

S = "${WORKDIR}/${BPN}-${PV}"
SDK_DIR = "${THISDIR}/../../rtk-dl"

FILES:${PN} += "${libdir}/*"
FILESEXTRAPATHS:append := ":${SDK_DIR}"

FILES_SOLIBSDEV = ""

INSANE_SKIP:${PN} += "already-stripped"
INSANE_SKIP:${PN} += "ldflags"
INSANE_SKIP:${PN} += "dev-so"

SOC_NAME:stark = "1619b"
SOC_NAME:kent = "kent"
SOC_NAME:prince = "prince"

LIBNPU_PATH_VIPLITE = "viplite/library/64bit"
LIBNPU_PATH_OVXLIB   = "ovxlib/library/acuity-root-dir/lib/arm64"

TENSOR_FILTER_PATH_VIPLITE = "viplite-nnstreamer/prebuilt"
TENSOR_FILTER_PATH_OVXLIB = "ovxlib/NNStreamer/prebuilt"

LIBNPU_INC_VIPLITE  = "viplite/header"
LIBNPU_INC_OVXLIB    = "ovxlib/library/acuity-root-dir/include"

OVXLIB_INC  = "ovxlib/library/acuity-root-dir/ovxlib-package-dev/arm64/include"

LIBNPU_PATH:stark = "${S}/${LIBNPU_PATH_OVXLIB}/${SOC_NAME}"
LIBNPU_PATH = "${S}/${LIBNPU_PATH_VIPLITE}/${SOC_NAME}/"
LIBNPU_INC_PATH:stark = "${S}/${LIBNPU_INC_OVXLIB}"
LIBNPU_INC_PATH = "${S}/${LIBNPU_INC_VIPLITE}/${SOC_NAME}/include"
OVXLIB_INC_PATH:stark = "${S}/${OVXLIB_INC}"
TENSOR_FILTER_PREBUILT_PATH = "${S}/${TENSOR_FILTER_PATH_VIPLITE}"
TENSOR_FILTER_PREBUILT_PATH:stark = "${S}/${TENSOR_FILTER_PATH_OVXLIB}"

do_install() {
    install -d ${D}${libdir}
    install -d ${D}${includedir}/npu_header
    install -d ${D}${libdir}/nnstreamer/filters
    install -m 0755 ${LIBNPU_PATH}/* ${D}${libdir}
    install -m 0755 ${TENSOR_FILTER_PREBUILT_PATH}/* ${D}${libdir}/nnstreamer/filters
    cp -r ${LIBNPU_INC_PATH}/* ${D}${includedir}/npu_header

    if [ -n "${OVXLIB_INC_PATH}" ]; then
        install -d ${D}${includedir}/npu_header/ovxlib
        cp -r ${OVXLIB_INC_PATH}/* ${D}${includedir}/npu_header/ovxlib
    fi
}