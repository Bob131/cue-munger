bin_PROGRAMS = cue-munge

cue_munge_SOURCES = \
	$(top_srcdir)/libgue/gue.vapi \
	cue-munge.vala
cue_munge_VALAFLAGS = \
	$(cue_U_VALAFLAGS)
cue_munge_CFLAGS = \
	-I $(top_srcdir)/libgue \
	-w \
	$(cue_U_CFLAGS)
cue_munge_LDADD = \
	$(top_srcdir)/libgue/libgue.la \
	$(cue_U_LIBS)

CLEANFILES = \
	$(cue_munge_SOURCES:%.vala=%.c) \
	*.stamp \
	*.stamp-t

dist-hook:
	cd $(distdir); rm -f $(CLEANFILES)
