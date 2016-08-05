SUBDIRS = tests

lib_LTLIBRARIES = libgue.la

include_HEADERS = gue.h
pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = libgue.pc

vapidir = $(datadir)/vala/vapi
vapi_DATA = gue-$(SHORT_VERSION).vapi gue-$(SHORT_VERSION).deps

girdir = $(datadir)/gir-1.0
gir_DATA = Gue-$(SHORT_VERSION).gir
typelibdir = $(libdir)/girepository-1.0
typelib_DATA = Gue-$(SHORT_VERSION).typelib


BUILT_SOURCES = \
	gue.h gue-priv.h \
	libgue.pc \
	gue-$(SHORT_VERSION).vapi gue-$(SHORT_VERSION).deps \
	Gue-$(SHORT_VERSION).gir Gue-$(SHORT_VERSION).typelib \
	scanner.c

gue-$(SHORT_VERSION).deps:
	$(AM_V_GEN) printf "gio-2.0\n" > $@

Gue-$(SHORT_VERSION).typelib: Gue-$(SHORT_VERSION).gir
	$(AM_V_GEN) g-ir-compiler --shared-library=libgue --output=$@ $<

scanner.c: scanner.rl
	$(AM_V_GEN) ragel -o $@ $<


libgue_la_SOURCES = \
	scanner.c \
	tokens.vala \
	evaluator.vala \
	libgue.vala
libgue_la_VALAFLAGS = \
	--library gue \
	-H gue.h -h gue-priv.h \
	--vapi gue-$(SHORT_VERSION).vapi \
	--gir Gue-$(SHORT_VERSION).gir \
	--vapidir . --pkg uchardet \
	$(cue_U_VALAFLAGS)
libgue_la_CFLAGS = \
	$(cue_U_CFLAGS)
libgue_la_LIBADD = \
	$(cue_U_LIBS)
libgue_la_LDFLAGS = \
	-release $(SHORT_VERSION)


CLEANFILES = \
	$(libgue_la_SOURCES:%.vala=%.c) \
	$(BUILT_SOURCES) \
	*.stamp

# clean up BUILT_SOURCES from prev versions
clean-local:
	rm -f *.gir *.typelib gue-*.vapi gue-*.deps

dist-hook:
	cd $(distdir); rm -f $(CLEANFILES)
