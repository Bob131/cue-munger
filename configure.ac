AC_INIT([cue-munger], [0.5])

AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([foreign subdir-objects])
AM_SILENT_RULES([yes])

AM_PROG_VALAC([0.28])
AM_PROG_CC_C_O

LT_INIT([disable-static])

CFLAGS="$CFLAGS -w"

dnl ###########################################################################
dnl Dependencies
dnl ###########################################################################

GLIB_REQUIRED=2.40.0

PKG_CHECK_MODULES(cue_U, [
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED
  uchardet
])

AC_SUBST([cue_U_VALAFLAGS], ["--pkg gio-2.0 \
          --target-glib=$GLIB_REQUIRED \
          --fatal-warnings \
          --enable-checking \
          --enable-experimental-non-null"])

AC_CHECK_PROG(RAGEL_CHECK,ragel,yes)
if test x"$RAGEL_CHECK" != x"yes"; then
  AC_MSG_ERROR([Cannot find ragel])
fi

GOBJECT_INTROSPECTION_CHECK([1.40.0])

GLIB_TESTS

dnl ###########################################################################
dnl Files to generate
dnl ###########################################################################

AC_CONFIG_FILES([
Makefile
libgue/Makefile
libgue/libgue.pc
libgue/tests/Makefile
src/Makefile
])
AC_OUTPUT
