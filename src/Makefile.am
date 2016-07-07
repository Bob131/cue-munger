bin_PROGRAMS = cue-munge

cue_munge_SOURCES = \
	cue-munge.vala
cue_munge_CFLAGS = \
	$(cue_munge_U_CFLAGS)
cue_munge_VALAFLAGS = \
	$(cue_munge_U_VALAFLAGS)
cue_munge_LDADD = \
	$(cue_munge_U_LIBS)

CLEANFILES = \
	$(cue_munge_SOURCES:%.vala=%.c) \
	*.stamp \
	*.stamp-t

dist-hook:
	cd $(distdir); rm -f $(CLEANFILES)
