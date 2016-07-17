Currently, libgue rigidly parses only a subset of cue sheet functionality, and
as such there are plenty of valid cue sheets that it will refuse to parse. This
is a list of known missing capabilities:
  * Only FILE types allowed are WAVE and MP3
  * The only TRACK type allowed is AUDIO
  * REM commands under FILE aren't allowed
  * No heed is paid to the number given by INDEX commands; the last one
    of either '00' or '01' available in the node tree is the one that gets used
    for start/duration. All others are ignored.
  * All numbers are two chars wide, with a leading zero pad if needed. This is
    obviously going to be an issue with long files or many tracks.
  * Commands libgue has no concept of:
    * CDTEXTFILE
    * FLAGS
    * POSTGAP
    * PREGAP
    * SONGWRITER
