#include "gue-priv.h"

#define MATCH g_strndup (match_start, p - match_start)
#define ADD(child) { \
  Node* node = NODE (child); \
  node->location = p - data; \
  tree_builder_add (builder, node); \
}

%%{
  machine cue_scanner;

  action MatchStart {
    match_start = fpc;
  }

  newline       = [\r\n];
  blank         = space - newline;

  delim         = blank+;

  quoted_string = ('"' (any - newline)+ '"');
  unquot_string = ^("'" | '"') ^(blank | newline)+;
  string        = quoted_string | unquot_string;

  catalog       = "CATALOG" % {ADD (catalog_command_new ());}
                    delim
                    digit {13} > MatchStart % {
                      ADD (barcode_argument_new (MATCH));
                    };

  file          = "FILE" % {ADD (file_command_new ());}
                    delim
                    string > MatchStart % {ADD (argument_new (MATCH));}
                    delim
                    ("WAVE" | "MP3") > MatchStart % {
                      ADD (file_type_argument_new (MATCH));
                    };

  index         = "INDEX" % {ADD (index_command_new ());}
                    delim
                    digit {2} > MatchStart % {
                      ADD (index_argument_new (MATCH));
                    }
                    delim
                    (digit | ':') {8} > MatchStart % {
                      ADD (timestamp_argument_new (MATCH));
                    };

  isrc          = "ISRC" % {ADD (isrc_command_new ());}
                    delim
                    alnum {12} > MatchStart % {
                      ADD (isrc_argument_new (MATCH));
                    };

  performer     = "PERFORMER" % {ADD (performer_command_new ());}
                    delim
                    string > MatchStart % {ADD (argument_new (MATCH));};

  rem           = "REM"
                    (
                      delim
                      (any - newline)+ > MatchStart % {
                        ADD (remark_command_new (MATCH));
                      }
                    )?;

  title         = "TITLE" % {ADD (title_command_new ());}
                    delim
                    string > MatchStart % {
                      ADD (argument_new (MATCH));
                    };

  track         = "TRACK" % {ADD (track_command_new ());}
                    delim
                    digit {2} > MatchStart % {
                      ADD (track_argument_new (MATCH));
                    }
                    delim
                    "AUDIO";

  command       = (catalog | file | index | isrc | performer | rem | title
                    | track);

  main := (delim* command? newline+)*;
}%%

%% write data;

void scan_cue(TreeBuilder* builder,
  const gchar* data,
  glong* pos,
  GError** error)
{
  int cs;

  const char* p = data;
  const char* pe = data + strlen(data);

  const char* match_start;

  %% write init;
  %% write exec;

  if (cs == cue_scanner_error)
    g_set_error(error, GUE_PARSE_ERROR, GUE_PARSE_ERROR_INVALID,
        "Failed to parse token");

  *pos = p - data;
  return;
}
