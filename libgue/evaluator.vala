/*
    The SList tree created in this file has a special (non-obvious) format:

    * The first file in SList<Node.File> does not represent a FILE command.
      It contains the cuesheet-wide data that appears at the start of the file.

    * The first track of each SList<Node.Track> (Node.File.tracks) does not
      represent a TRACK command. It's just a container for the FILE command
      itself.

    So the tree for a dummy cue sheet like

        TITLE "Test CD"
        FILE "test.wav" WAVE
          TRACK 01 AUDIO
            TITLE "Test Track"

    could be represented with a JSON-like syntax as

        files: [
            {tracks: [{title: ["Test CD"]}] },
            {tracks: [
                {file: [test.wav, WAVE]},
                {track: [01, AUDIO], title: ["Test Track"]}
            ]}
        ]

    This is fairly undesirable, but it seems to be the best way to keep
    Evaluator.add_command readable and concise. Hopefully this will be
    changed to be less bewildering in the future.
*/


internal class Evaluator : Object {
    public SList<Node.File> files;

    public void add_command(string str) throws Gue.ParseError {
        var command = Token.Command.from_string(str);

        if (command == Token.Command.FILE)
            files.prepend(new Node.File());
        else if (command == Token.Command.TRACK)
            files.data.tracks.prepend(new Node.Track());
        else if (files.data.tracks.length() == 1 && files.length() > 1)
            throw new Gue.ParseError.INVALID("Illegal command '%s' (%s)", str,
                "the only valid command after FILE is TRACK");

        files.data.tracks.data.commands.prepend(new Node.Command(command));
    }

    public void add_string(string str) {
        files.data.tracks.data.commands.data.arguments.prepend(str);
    }

    construct {
        files.prepend(new Node.File());
    }
}

extern void scan_cue(
    Evaluator eval,
    string data,
    out long pos
) throws Gue.ParseError;

SList<Node.File> lex_cue(string data) throws Gue.ParseError {
    var eval = new Evaluator();

    long pos;
    try {
        scan_cue(eval, data, out pos);
    } catch (Gue.ParseError e) {
        e.message = "%s on line %d".printf(e.message,
            data[0:pos].split("\n").length);
        throw e;
    }

    foreach (var file in eval.files) {
        foreach (var track in file.tracks) {
            foreach (var command in track.commands)
                command.arguments.reverse();
            track.commands.reverse();
        }
        file.tracks.reverse();
    }
    eval.files.reverse();

    return (owned) eval.files;
}
