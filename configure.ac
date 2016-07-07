AC_INIT([cue-munge], m4_esyscmd_s([echo "0-`git describe --always`"]))

AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([foreign subdir-objects])
AM_SILENT_RULES([yes])

AM_PROG_VALAC([0.28])
AM_PROG_CC_C_O

dnl ###########################################################################
dnl Dependencies
dnl ###########################################################################

GLIB_REQUIRED=2.40.0

PKG_CHECK_MODULES(cue_munge_U, [
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED
  libcue
])

AC_SUBST([cue_munge_U_VALAFLAGS], ["--pkg gio-2.0 \
          --vapidir \$(top_srcdir)/vapi \
          --pkg libcue \
          --target-glib=$GLIB_REQUIRED \
          --fatal-warnings \
          --enable-experimental-non-null"])

CFLAGS="$CFLAGS -w"

dnl ###########################################################################
dnl Files to generate
dnl ###########################################################################

AC_CONFIG_FILES([
Makefile
src/Makefile
])
AC_OUTPUT
