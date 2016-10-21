const string PATHOLOGICAL_EAC_CUE_SHEET = """
REM GENRE Hip-Hop
REM DATE 2014
REM DISCID DA0DA811
REM COMMENT "ExactAudioCopy v1.0b3"
CATALOG 0602537825257
PERFORMER "Iggy Azalea"
TITLE "The New Classic"
FILE "001-iggy_azalea-walk_the_line.flac" WAVE
  TRACK 01 AUDIO
    TITLE "Walk The Line"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71306938
    INDEX 01 00:00:00
FILE "002-iggy_azalea-dont_need_yall.flac" WAVE
  TRACK 02 AUDIO
    TITLE "Don't Need Y'all"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71401080
    INDEX 01 00:00:00
FILE "003-iggy_azalea-100_(feat._watch_the_duck).flac" WAVE
  TRACK 03 AUDIO
    TITLE "100 (Feat. Watch The Duck)"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71401090
    INDEX 01 00:00:00
FILE "004-iggy_azalea-change_your_life_(feat._t.i.).flac" WAVE
  TRACK 04 AUDIO
    TITLE "Change Your Life (Feat. T.I.)"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71303219
    INDEX 01 00:00:00
FILE "005-iggy_azalea-fancy_(feat._charli_xcx).flac" WAVE
  TRACK 05 AUDIO
    TITLE "Fancy (Feat. Charli XCX)"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71400597
    INDEX 01 00:00:00
FILE "006-iggy_azalea-new_bitch.flac" WAVE
  TRACK 06 AUDIO
    TITLE "New Bitch"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71401085
    INDEX 01 00:00:00
FILE "007-iggy_azalea-work.flac" WAVE
  TRACK 07 AUDIO
    TITLE "Work"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71301347
    INDEX 01 00:00:00
FILE "008-iggy_azalea-impossible_is_nothing.flac" WAVE
  TRACK 08 AUDIO
    TITLE "Impossible Is Nothing"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71306811
    INDEX 01 00:00:00
FILE "009-iggy_azalea-goddess.flac" WAVE
  TRACK 09 AUDIO
    TITLE "Goddess"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71401087
    INDEX 01 00:00:00
FILE "010-iggy_azalea-black_widow_(feat._rita_ora).flac" WAVE
  TRACK 10 AUDIO
    TITLE "Black Widow (Feat. Rita Ora)"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71401093
    INDEX 01 00:00:00
FILE "011-iggy_azalea-lady_patra_(feat._mavado).flac" WAVE
  TRACK 11 AUDIO
    TITLE "Lady Patra (Feat. Mavado)"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71401089
    INDEX 01 00:00:00
FILE "012-iggy_azalea-fuck_love.flac" WAVE
  TRACK 12 AUDIO
    TITLE "Fuck Love"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71401082
    INDEX 01 00:00:00
FILE "013-iggy_azalea-bounce.flac" WAVE
  TRACK 13 AUDIO
    TITLE "Bounce"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71301908
    INDEX 01 00:00:00
FILE "014-iggy_azalea-rolex.flac" WAVE
  TRACK 14 AUDIO
    TITLE "Rolex"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71401095
    INDEX 01 00:00:00
FILE "015-iggy_azalea-just_askin.flac" WAVE
  TRACK 15 AUDIO
    TITLE "Just Askin'"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71301928
    INDEX 01 00:00:00
  TRACK 16 AUDIO
    TITLE "Fancy (Feat. Charli XCX) (GTA Remix)"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71401638
    INDEX 00 02:59:08
FILE "016-iggy_azalea-fancy_(feat._charli_xcx)_(gta_remix).flac" WAVE
    INDEX 01 00:00:00
  TRACK 17 AUDIO
    TITLE "Bounce (Jester Remix)"
    PERFORMER "Iggy Azalea"
    ISRC GBUM71401715
    INDEX 00 04:11:69
FILE "017-iggy_azalea-bounce_(jester_remix).flac" WAVE
    INDEX 01 00:00:00
""";


void pathological_eac_test() {
    Gue.Sheet sheet;
    try {
        sheet = new Gue.Sheet.parse_data(PATHOLOGICAL_EAC_CUE_SHEET.data);
    } catch (Error e) {
        error(e.message);
    }

    assert ((!) sheet.title == "The New Classic");
    assert ((!) sheet.performer == "Iggy Azalea");
    assert ((!) sheet.barcode == "0602537825257");

    assert (sheet.comments[0] == "GENRE Hip-Hop");
    assert (sheet.comments[1] == "DATE 2014");
    assert (sheet.comments[2] == "DISCID DA0DA811");
    assert (sheet.comments[3] == "COMMENT \"ExactAudioCopy v1.0b3\"");

    assert (sheet.tracks.size == 17);
    assert (sheet.files.size == 17);

    foreach (var file in sheet.files)
        assert (file.tracks.size == 1);

    assert (sheet.files[0].tracks[0] == sheet.tracks[0]);
    assert ((!) sheet.tracks[0].title == "Walk The Line");
    assert (sheet.tracks[0].number == 1);
    assert (sheet.tracks[0].start_time == 0);
    assert (sheet.tracks[0].length == null);
    assert ((!) sheet.tracks[0].isrc == "GBUM71306938");

    assert (sheet.files[15].tracks[0] == sheet.tracks[15]);
    assert ((!) sheet.tracks[15].title
        == "Fancy (Feat. Charli XCX) (GTA Remix)");
    assert (sheet.tracks[15].number == 16);
    assert (sheet.tracks[15].start_time == 0);
    assert (sheet.tracks[15].length == 251.92);

    assert (sheet.tracks[16].length == null);
}
