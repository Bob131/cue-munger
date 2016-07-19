internal class Evaluator : Object {
    public SList<Node.Track> tracks;

    public void add_command(string str) throws Gue.ParseError {
        var command = Token.Command.from_string(str);

        if (command == Token.Command.TRACK)
            tracks.prepend(new Node.Track());

        tracks.data.commands.prepend(new Node.Command(command));
    }

    public void add_string(string str) {
        tracks.data.commands.data.arguments.prepend(str);
    }

    construct {
        tracks.prepend(new Node.Track());
    }
}

extern void scan_cue(
    Evaluator eval,
    string data,
    out long pos
) throws Gue.ParseError;

SList<Node.Track> lex_cue(string data) throws Gue.ParseError {
    var eval = new Evaluator();

    long pos;
    try {
        scan_cue(eval, data, out pos);
    } catch (Gue.ParseError e) {
        e.message = "%s on line %d".printf(e.message,
            data[0:pos].split("\n").length);
        throw e;
    }

    foreach (var track in eval.tracks) {
        foreach (var command in track.commands)
            command.arguments.reverse();
        track.commands.reverse();
    }
    eval.tracks.reverse();

    return (owned) eval.tracks;
}
