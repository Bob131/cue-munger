void utf16_test() {
    Gue.Sheet sheet;
    try {
        sheet = new Gue.Sheet.parse_file(File.new_for_path(
            Test.get_filename(Test.FileType.DIST, "utf16-test.cue")));
    } catch (Error e) {
        error(e.message);
    }
    // make sure we haven't received any encoding warnings
    Test.assert_expected_messages();

    assert ((!) sheet.title == "Love.Angel.Music.Baby.");
    assert ((!) sheet.performer == "Gwen Stefani");

    assert (sheet.comments.size == 2);
    assert (sheet.comments[0] == "GENRE Pop");
    assert (sheet.comments[1] == "DATE 2004");

    foreach (var file in sheet.files)
        assert (file.file_type == Gue.FileType.WAVE);

    assert (sheet.files.size == sheet.tracks.size);
    for (var i = 0; i < sheet.tracks.size; i++)
        assert (sheet.files[i].tracks[0] == sheet.tracks[i]);

    assert (sheet.files[0].name ==
        "Stefani, Gwen - Love.Angel.Music.Baby. - 01 - What You Waiting For.flac");
    assert ((!) sheet.tracks[0].title == "What You Waiting For?");
    assert ((!) sheet.tracks[0].performer == "Gwen Stefani");
    assert (sheet.tracks[0].start_time == 0);

    assert (sheet.files[1].name ==
        "Stefani, Gwen - Love.Angel.Music.Baby. - 02 - Rich Girl.flac");
    assert ((!) sheet.tracks[1].title == "Rich Girl");
    assert ((!) sheet.tracks[1].performer == "Gwen Stefani [Feat. Eve]");
    assert (sheet.tracks[1].start_time == 0);
}
