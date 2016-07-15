bin_PROGRAMS = cue-munger

cue_munger_SOURCES = \
	$(top_srcdir)/libgue/gue.vapi \
	mungers/musicbrainz.vala \
	cue-munger.vala
cue_munger_VALAFLAGS = \
	$(cue_U_VALAFLAGS)
cue_munger_CFLAGS = \
	-I $(top_srcdir)/libgue \
	-w \
	$(cue_U_CFLAGS)
cue_munger_LDADD = \
	$(top_srcdir)/libgue/libgue.la \
	-lm \
	$(cue_U_LIBS)

CLEANFILES = \
	$(cue_munger_SOURCES:%.vala=%.c) \
	*.stamp \
	*.stamp-t

dist-hook:
	cd $(distdir); rm -f $(CLEANFILES)
