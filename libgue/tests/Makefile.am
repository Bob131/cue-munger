include $(top_srcdir)/build-aux/glib-tap.mk

test_programs = \
	tests

tests_SOURCES = \
	../gue-$(VERSION).vapi \
	eac-test.vala \
	tests.vala
tests_VALAFLAGS = $(cue_U_VALAFLAGS)
tests_CFLAGS = \
	-I../ \
	$(cue_U_CFLAGS)
tests_LDADD = \
	../libgue.la \
	$(cue_U_LIBS)

CLEANFILES += \
	*.c \
	*.stamp
