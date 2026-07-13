# Bump pseudo to the 1.9.3 release (as shipped in Yocto Scarthgap 5.0.16) for
# openat2() syscall interception. Without it, GNU tar's raw openat2() calls are
# invisible to pseudo, so do_package's image->package copy fails with
# "tar: Cannot mkdir: Bad address" (EFAULT) on hosts with a newer tar/glibc.
# Kept in meta-rtk so poky's meta/ stays pristine.

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRCREV = "9ab513512d8b5180a430ae4fa738cb531154cdef"
PV = "1.9.3+git"

# Both are folded into 1.9.3 upstream; drop them from the 1.9.0 base recipe.
SRC_URI:remove = "file://0001-configure-Prune-PIE-flags.patch file://glibc238.patch"

# older-glibc-symbols.patch is refreshed for 1.9.3 (adds pseudo_client_scanf.o)
# and is picked up from this layer's files/ via FILESEXTRAPATHS above.

# Companion fix (5.0.16): ensure fakeroot setscene tasks don't run before
# pseudo-native and its runtime deps are staged.
PSEUDO_SETSCENE_DEPS = ""
PSEUDO_SETSCENE_DEPS:class-native = "sqlite3-native:do_populate_sysroot"
do_populate_sysroot_setscene[depends] += "${PSEUDO_SETSCENE_DEPS}"
