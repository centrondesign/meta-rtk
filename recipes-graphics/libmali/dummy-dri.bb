SUMMARY = "Provide minimal dri.pc for Chromium GN"
LICENSE = "MIT"

S = "${WORKDIR}"
inherit allarch

do_install() {
    install -d ${D}${libdir}/pkgconfig
    cat > ${D}${libdir}/pkgconfig/dri.pc << 'EOF'
prefix=/usr
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include

Name: dri
Description: Dummy DRI pkg-config for Chromium build
Version: 1.0
dridriverdir=${libdir}/dri
EOF
}

