include $(top_srcdir)/build-aux/glib-tap.mk

test_programs = \
	parser-test

parser_test_SOURCES = \
	../gue-$(VERSION).vapi \
	parser-test.vala
parser_test_VALAFLAGS = $(cue_U_VALAFLAGS)
parser_test_CFLAGS = \
	-I../ \
	$(cue_U_CFLAGS)
parser_test_LDADD = \
	../libgue.la \
	$(cue_U_LIBS)

CLEANFILES += \
	*.c \
	*.stamp
