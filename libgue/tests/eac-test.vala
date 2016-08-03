const string EAC_CUE_SHEET = """REM GENRE Pop
REM DATE 2015
REM DISCID 170DCE14
REM COMMENT "ExactAudioCopy v1.0b3"
PERFORMER "Various Artists"
TITLE "Eurovision Song Contest 2015 - Disc 1"
FILE "01 - Elhaida Dani - I'm Alive.wav" WAVE
  TRACK 01 AUDIO
    TITLE "I'm Alive"
    PERFORMER "Elhaida Dani"
    INDEX 01 00:00:00
  TRACK 02 AUDIO
    TITLE "Face The Shadow"
    PERFORMER "Genealogy"
    INDEX 00 03:06:23
FILE "02 - Genealogy - Face The Shadow.wav" WAVE
    INDEX 01 00:00:00
  TRACK 03 AUDIO
    TITLE "I Am Yours"
    PERFORMER "The Makemakes"
    INDEX 00 03:00:37
FILE "03 - The Makemakes - I Am Yours.wav" WAVE
    INDEX 01 00:00:00
  TRACK 04 AUDIO
    TITLE "Tonight Again"
    PERFORMER "Guy Sebastian"
    INDEX 00 03:00:55
FILE "04 - Guy Sebastian - Tonight Again.wav" WAVE
    INDEX 01 00:00:00
  TRACK 05 AUDIO
    TITLE "Hour Of The Wolf"
    PERFORMER "Elnur Huseynov"
    INDEX 00 02:55:65
FILE "05 - Elnur Huseynov - Hour Of The Wolf.wav" WAVE
    INDEX 01 00:00:00
  TRACK 06 AUDIO
    TITLE "Rhythm Inside"
    PERFORMER "Loic Nottet"
    INDEX 00 02:59:18
FILE "06 - Loic Nottet - Rhythm Inside.wav" WAVE
    INDEX 01 00:00:00
  TRACK 07 AUDIO
    TITLE "Time"
    PERFORMER "Uzari & Maimuna"
    INDEX 00 02:52:12
FILE "07 - Uzari & Maimuna - Time.wav" WAVE
    INDEX 01 00:00:00
  TRACK 08 AUDIO
    TITLE "Time To Shine"
    PERFORMER "Melanie Rene"
    INDEX 00 03:00:44
FILE "08 - Melanie Rene - Time To Shine.wav" WAVE
    INDEX 01 00:00:00
  TRACK 09 AUDIO
    TITLE "One Thing I Should Have Done"
    PERFORMER "John Karayiannis"
    INDEX 00 03:02:37
FILE "09 - John Karayiannis - One Thing I Should Have Done.wav" WAVE
    INDEX 01 00:00:00
  TRACK 10 AUDIO
    TITLE "Hope Never Dies"
    PERFORMER "Marta Jandova & Vaclav Noid Barta"
    INDEX 00 03:02:31
FILE "10 - Marta Jandova & Vaclav Noid Barta - Hope Never Dies.wav" WAVE
    INDEX 01 00:00:00
  TRACK 11 AUDIO
    TITLE "Black Smoke"
    PERFORMER "Ann Sophie"
    INDEX 00 03:04:68
FILE "11 - Ann Sophie - Black Smoke.wav" WAVE
    INDEX 01 00:00:00
  TRACK 12 AUDIO
    TITLE "The Way You Are"
    PERFORMER "Anti Social Media"
    INDEX 00 03:00:01
FILE "12 - Anti Social Media - The Way You Are.wav" WAVE
    INDEX 01 00:00:00
  TRACK 13 AUDIO
    TITLE "Goodbye To Yesterday"
    PERFORMER "Elina Born & Stig Rasta"
    INDEX 00 03:01:06
FILE "13 - Elina Born & Stig Rasta - Goodbye To Yesterday.wav" WAVE
    INDEX 01 00:00:00
  TRACK 14 AUDIO
    TITLE "Amanecer"
    PERFORMER "Edurne"
    INDEX 00 02:59:11
FILE "14 - Edurne - Amanecer.wav" WAVE
    INDEX 01 00:00:00
  TRACK 15 AUDIO
    TITLE "Aina Mun Pitaa"
    PERFORMER "Pertti Kurikan Nimipaivat"
    INDEX 00 03:04:35
FILE "15 - Pertti Kurikan Nimipaivat - Aina Mun Pitaa.wav" WAVE
    INDEX 01 00:00:00
  TRACK 16 AUDIO
    TITLE "N'oubliez Pas"
    PERFORMER "Lisa Angell"
    INDEX 00 01:28:10
FILE "16 - Lisa Angell - N'oubliez Pas.wav" WAVE
    INDEX 01 00:00:00
  TRACK 17 AUDIO
    TITLE "Still In Love With You"
    PERFORMER "Electro Velvet"
    INDEX 00 03:00:38
FILE "17 - Electro Velvet - Still In Love With You.wav" WAVE
    INDEX 01 00:00:00
  TRACK 18 AUDIO
    TITLE "Warrior"
    PERFORMER "Nina Sublatti"
    INDEX 00 02:48:68
FILE "18 - Nina Sublatti - Warrior.wav" WAVE
    INDEX 01 00:00:00
  TRACK 19 AUDIO
    TITLE "One Last Breath"
    PERFORMER "Maria Elena Kyriakou"
    INDEX 00 03:02:11
FILE "19 - Maria Elena Kyriakou - One Last Breath.wav" WAVE
    INDEX 01 00:00:00
  TRACK 20 AUDIO
    TITLE "Wars For Nothing"
    PERFORMER "Boggie"
    INDEX 00 02:47:60
FILE "20 - Boggie - Wars For Nothing.wav" WAVE
    INDEX 01 00:00:00""";


void eac_test() {
    Test.expect_message(null, LogLevelFlags.LEVEL_WARNING,
        "*ExactAudioCopy*disabled");
    Gue.Sheet sheet;
    try {
        sheet = new Gue.Sheet.parse_data(EAC_CUE_SHEET.data);
    } catch (Error e) {
        error(e.message);
    }
    Test.assert_expected_messages();

    assert ((!) sheet.title == "Eurovision Song Contest 2015 - Disc 1");
    assert ((!) sheet.performer == "Various Artists");

    assert (sheet.generated_by_eac);
    assert (sheet.files.length == 0);

    assert (sheet.comments[0] == "GENRE Pop");
    assert (sheet.comments[1] == "DATE 2015");
    assert (sheet.comments[2] == "DISCID 170DCE14");
    assert (sheet.comments[3] == "COMMENT ExactAudioCopy v1.0b3");

    assert (sheet.tracks.length == 20);

    assert ((!) sheet.tracks[0].title == "I'm Alive");
    assert ((!) sheet.tracks[0].performer == "Elhaida Dani");
    assert (sheet.tracks[0].number == 1);
    assert (sheet.tracks[0].start_time == null);
    assert (sheet.tracks[0].length == null);

    assert ((!) sheet.tracks[1].title == "Face The Shadow");
    assert ((!) sheet.tracks[1].performer == "Genealogy");
    assert (sheet.tracks[1].number == 2);
    assert (sheet.tracks[1].start_time == null);
    assert (sheet.tracks[1].length == null);

    assert ((!) sheet.tracks[2].title == "I Am Yours");
    assert ((!) sheet.tracks[2].performer == "The Makemakes");
    assert (sheet.tracks[2].number == 3);
    assert (sheet.tracks[2].start_time == null);
    assert (sheet.tracks[2].length == null);
}
