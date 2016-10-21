string line_offset(long pos, string buffer) {
    var copy = buffer[0 : pos];
    var lines = copy.split("\n");

    var line_template = "line %d, column %d";

    if (lines.length == 0)
        return line_template.printf(1, pos + 1);

    return line_template.printf(lines.length,
        lines[lines.length - 1].length + 1);
}

internal class TreeBuilder : Object {
    RootNode root;
    Node head;

    Node? find(Type type) {
        Node ret = head;
        while (Type.from_instance(ret) != type)
            if (ret.parent != null)
                ret = (!) ret.parent;
            else
                return null;
        return ret;
    }

    void seek(Type[] types)
        requires (types.length > 0)
    {
        Node? new_head = null;

        for (var i = 0; i < types.length && new_head == null; i++)
            new_head = find(types[i]);

        if (new_head == null)
            critical("Failed to seek head to %s", types[0].name());
        else
            head = (!) new_head;
    }

    void seek_and_add(Type[] types, Node child)
        requires (child is Command)
    {
        seek(types);
        head.add(child);
        head = ((Command) child).args;
    }

    public void add(Node child) {
        if (child is CatalogCommand || child is FileCommand)
            seek_and_add({typeof(RootNode)}, child);

        else if (child is TrackCommand)
            seek_and_add({typeof(FileCommand)}, child);

        else if (child is TitleCommand || child is PerformerCommand)
            seek_and_add({typeof(TrackCommand), typeof(RootNode)}, child);

        else if (child is IndexCommand) {
            seek({typeof(TrackCommand), typeof(FileCommand)});

            if (head is FileCommand)
                // This tries to re-order tracks so we can parse ExactAudioCopy
                // cuesheets properly
                if (head.prev is FileCommand
                    && ((FileCommand) head.prev).tracks.length == 2)
                {
                    var prev = (FileCommand) head.prev;
                    var our_track = (owned) prev.children[2];
                    prev.children.resize(2);

                    ((!) our_track.prev).next = null;
                    our_track.parent = null;

                    head.add(our_track);
                    head = our_track;
                } else
                    critical("Track reshuffling failed");

            head.add(child);
            head = ((Command) child).args;

        } else if (child is IsrcCommand)
            seek_and_add({typeof(TrackCommand)}, child);

        else if (child is Argument && head is Arguments)
            head.add(child);

        else if (child is RemarkCommand) {
            var prev_head = head;
            seek_and_add({typeof(RootNode)}, child);
            head = prev_head;

        } else
            critical("Unhandled %s", Type.from_instance(child).name());
    }

    public RootNode end() throws Gue.ParseError {
        root.validate();
        return root;
    }

    public TreeBuilder(string data) {
        root = new RootNode(data);
        head = root;
    }
}

extern void scan_cue(
    TreeBuilder builder,
    string data,
    out long pos
) throws Gue.ParseError;

RootNode lex_cue(string data) throws Gue.ParseError {
    var builder = new TreeBuilder(data);

    long pos;
    try {
        scan_cue(builder, data, out pos);
    } catch (Gue.ParseError e) {
        e.message = "%s at %s".printf(e.message,
            line_offset(pos, data));
        throw e;
    }

    return builder.end();
}
