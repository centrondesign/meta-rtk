SUMMARY = "ARM libmali"
LICENSE = "CLOSED"

inherit bin_package pkgconfig

DISTRO_FEATURES:append = "usrmerge"
DEPENDS += "wayland libdrm"

PROVIDES = "virtual/libgles2 virtual/egl virtual/libgbm virtual/libgl"

PREBUILT_DIR:hank = "malig57-r54p1-12eac0-wayland-drm-a64"
PREBUILT_DIR:stark = "malig57-r54p1-12eac0-wayland-drm-a64"
PREBUILT_DIR:kent = "malig310-r54p1-11eac0-wayland-drm-a64"
PREBUILT_DIR:prince = "malig310-r54p1-11eac0-wayland-drm-a64"

# rtd16xx mali um for aosp is dummy
PREBUILT_DIR:rtd16xx = "malig57-r54p1-12eac0-wayland-drm-a64"

SRCREV = "${AUTOREV}"
SRC_URI = "file://${PREBUILT_DIR}.tar.bz2"

S = "${WORKDIR}/${PREBUILT_DIR}"

FILES:${PN} += "${libdir}/* ${base_libdir}/*"

FILES_SOLIBSDEV = ""

INSANE_SKIP:${PN} += "already-stripped"
INSANE_SKIP:${PN} += "ldflags"
INSANE_SKIP:${PN} += "dev-so"
