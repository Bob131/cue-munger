lib_LTLIBRARIES = libgue.la

include_HEADERS = gue.h
guevapidir = $(datadir)/vala/vapi
guevapi_DATA = gue.vapi gue.deps


BUILT_SOURCES = gue.h gue-priv.h gue.vapi gue.deps scanner.c

gue.deps:
	$(AM_V_GEN) printf "gio-2.0\n" > $@

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
	--vapi gue.vapi \
	$(cue_U_VALAFLAGS)
libgue_la_CFLAGS = \
	$(cue_U_CFLAGS)
libgue_la_LIBADD = \
	$(cue_U_LIBS)


CLEANFILES = \
	$(libgue_la_SOURCES:%.vala=%.c) \
	$(BUILT_SOURCES) \
	*.stamp

dist-hook:
	cd $(distdir); rm -f $(CLEANFILES)
