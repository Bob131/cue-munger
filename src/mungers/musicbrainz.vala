class MusicBrainz : BaseMunger {
    public override string name {get {return "mb";}}
    public override string description {get {
        return "prints out a table suitable for the MusicBrainz track parser";
    }}

    public override string munge(Gue.Sheet cue_sheet) throws MungeError {
        if (cue_sheet.title == null)
            throw new MungeError.ERROR("Disc has no title");

        string[] lines = {};

        foreach (var track in cue_sheet.tracks) {
            var length_str = "?:??";
            var length = track.length;
            if (length != null)
                length_str = "%.f:%02.f".printf(Math.floor(length / 60),
                    Math.round(length % 60));

            lines += "%d. %s - %s (%s)".printf(track.number,
                (!) (track.title ?? "[untitled]"),
                (!) (track.performer ?? "[unknown]"),
                length_str);
        }

        return string.joinv("\n", (string?[]?) lines);
    }
}
