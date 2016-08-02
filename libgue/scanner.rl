#include "gue-priv.h"

%%{
    machine cue_scanner;

    blank         = [\t ];
    newline       = [\r\n];

    delim         = blank+;

    action MatchStart {
        match_start = fpc;
    }

    action StringEnd {
        evaluator_add_string(eval, g_strndup(match_start, fpc - match_start));
    }

    quoted_string = ('"' ^('"' | newline)+ '"') | ("'" ^("'" | newline)+ "'");
    unquot_string = ^("'" | '"') ^(blank | newline)+;
    string        = (quoted_string > MatchStart % {
                        evaluator_add_string(eval,
                            g_strndup(match_start + 1, fpc - match_start - 2));
                        }
                    | unquot_string > MatchStart % StringEnd);

    action CmdEnd {
        evaluator_add_command(eval, g_strndup(match_start, fpc - match_start),
            error);
        if (*error != NULL) {
            p = match_start;
            goto ret;
        }
    }

    catalog       = "CATALOG" > MatchStart % CmdEnd
                        delim
                        digit {13} > MatchStart % StringEnd;
    file          = "FILE" > MatchStart % CmdEnd
                        delim
                        string
                        delim
                        ("WAVE" | "MP3") > MatchStart % StringEnd;
    index         = "INDEX" > MatchStart % CmdEnd
                        delim
                        ("00" | "01") > MatchStart % StringEnd
                        delim
                        (digit {2} ':' digit {2} ':' digit {2})
                            > MatchStart % StringEnd;
    isrc          = "ISRC" > MatchStart % CmdEnd
                        delim
                        (alpha {2} alnum {3} digit {7})
                            > MatchStart % StringEnd;
    performer     = "PERFORMER" > MatchStart % CmdEnd
                        delim
                        string;
    rem           = "REM" > MatchStart % CmdEnd
                        (delim string)*;
    title         = "TITLE" > MatchStart % CmdEnd
                        delim
                        string;
    track         = "TRACK" > MatchStart % CmdEnd
                        delim
                        digit {2} > MatchStart % StringEnd
                        delim
                        "AUDIO";

    command       = (catalog | file | index | isrc | performer | rem | title
                        | track);

    main := (delim* command newline+)*;

}%%
    /* main := ( */
    /*     delim* */
    /*     (string > MatchBegun % { */
    /*         evaluator_add_command( */
    /*             eval, g_strndup(match_start, fpc - match_start), error); */
    /*         if (*error != NULL) { */
    /*             p = match_start; */
    /*             goto ret; */
    /*         } */
    /*     }) */
    /*     (delim+ (quoted_string > MatchBegun % { */
    /*         evaluator_add_string(eval, */
    /*             g_strndup(match_start + 1, fpc - match_start - 2)); */
    /*     } | string > MatchBegun % { */
    /*         evaluator_add_string(eval, */
    /*             g_strndup(match_start, fpc - match_start)); */
    /*     }))* */
    /*     newline+ */
    /* )*; */

%% write data;

void scan_cue(Evaluator* eval, const gchar* data, glong* pos, GError** error) {
    int cs;

    const char* p = data;
    const char* pe = data + strlen(data);

    const char* match_start;

    %% write init;
    %% write exec;

    if (cs == cue_scanner_error)
        g_set_error(error, GUE_PARSE_ERROR, GUE_PARSE_ERROR_INVALID,
            "Failed to parse token");

ret:
    *pos = p - data;
    return;
}
