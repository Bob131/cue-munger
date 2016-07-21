namespace Gue {
    public errordomain ParseError {
        UNKNOWN,
        INVALID,
        EMPTY
    }

    internal class StringValues {
        HashTable<Token.Command*, string?> values =
            new HashTable<Token.Command*, string?>(int_hash, str_equal);

        Token.Command[] _valid_keys = {};
        public Token.Command[] valid_keys {get {return _valid_keys;}}

        public void set_valid(Token.Command[] keys) {
            foreach (var key in keys)
                _valid_keys += key;
        }

        public bool @set(Node.Command command) throws ParseError {
            if (!(command.command in valid_keys)
                    || command.arguments.length() != 1)
                return false;
            if (values.contains(&command.command))
                throw new ParseError.INVALID("%s already set",
                    command.command.to_string());
            values.set(&command.command, command.arguments.data);
            return true;
        }

        public unowned string? @get(Token.Command key) {
            return values.get(&key);
        }
    }

    public abstract class Container : Object {
        internal StringValues values = new StringValues();

        Token.Command[] valid_keys = {Token.Command.TITLE,
            Token.Command.PERFORMER};
        public string? title {get {return values[Token.Command.TITLE];}}
        public string? performer {get {return values[Token.Command.PERFORMER];}}

        internal string[] _comments = {};
        public string[] comments {owned get {return _comments;}}

        internal bool parse_node(Node.Command command) throws ParseError {
            if (command.command == Token.Command.REM) {
                var comment = "";
                foreach (var arg in command.arguments)
                    comment += arg;
                _comments += comment;
                return true;
            }
            return values.set(command);
        }

        internal Container() {
            values.set_valid(valid_keys);
        }
    }

    public class Track : Container {
        Token.Command[] valid_keys = {Token.Command.ISRC};
        public string? isrc {get {return this.values[Token.Command.ISRC];}}

        internal int _number;
        public int number {get {return _number;}}

        internal float? _start_time = null;
        public float? start_time {get {return _start_time;}}

        internal float? _length = null;
        public float? length {get {return _length;}}

        weak Sheet parent;

        internal new bool parse_node(Node.Command command) throws ParseError {
            if (command.command == Token.Command.INDEX) {
                if (command.arguments.data == "00"
                        || command.arguments.data == "01") {
                    uint minutes, seconds, frames;
                    command.arguments.next.data.scanf("%02d:%02d:%02d",
                        out minutes, out seconds, out frames);
                    if (seconds >= 60)
                        throw new ParseError.INVALID(
                            "'%u' is an invalid seconds value", seconds);
                    if (frames >= 75)
                        throw new ParseError.INVALID(
                            "'%u' is an invalid frames value", frames);
                    _start_time =
                        (minutes * 60) + seconds + (frames * (1f / 75f));
                    if (parent._tracks.length > 0) {
                        var prev = parent._tracks[parent._tracks.length-1];
                        if (prev.start_time != null) {
                            prev._length = _start_time - prev.start_time;
                        }
                    }
                }
                return true;
            }
            return base.parse_node(command);
        }

        internal Track(Sheet parent, Node.Command track)
            requires (track.command == Token.Command.TRACK)
        {
            this.values.set_valid(valid_keys);
            this.parent = parent;
            _number = int.parse(track.arguments.data);
        }
    }

    public class Sheet : Container {
        Token.Command[] valid_keys = {Token.Command.CATALOG};
        public string? barcode {get {
            return this.values[Token.Command.CATALOG];
        }}

        internal Track[] _tracks = {};
        public Track[] tracks {owned get {return _tracks;}}

        public Sheet.parse_file(File file) throws Error {
            uint8[] data;
            string _;
            file.load_contents(null, out data, out _);
            Sheet.parse_data(data);
        }

        public async Sheet.parse_file_async(GLib.File file) throws Error {
            uint8[] data;
            string _;
            yield file.load_contents_async(null, out data, out _);
            Sheet.parse_data(data);
        }

        public Sheet.parse_data(uint8[] data) throws ParseError {
            var detect = new CharsetDetect.Context();
            detect.handle_data((string) data, data.length);
            detect.data_end();
            var charset = detect.get_charset().dup();

            string copy;

            if (charset == "") {
                warning("Unknown character encoding, %s",
                    "defaulting to UTF-8");
                charset = "UTF-8";
            }

            if (charset != "UTF-8")
                try {
                    copy = convert((string) data, data.length, "UTF-8",
                        charset);
                    if (!((!) copy).validate())
                        throw new ConvertError.ILLEGAL_SEQUENCE(
                            "Output isn't valid UTF-8");
                } catch (ConvertError e) {
                    throw new ParseError.INVALID(
                        "Failed to convert encoding from %s to UTF-8: %s",
                        charset, e.message);
                }
            else
                copy = (string) data;

            if (copy.has_prefix("\xef\xbb\xbf"))
                copy = copy[3:copy.length];

            var parse_tree = lex_cue((!) copy);
            if (parse_tree.length() == 1)
                throw new ParseError.EMPTY("Cue sheet appears to be empty");

            this.values.set_valid(valid_keys);

            Node.Command? default_performer_node = null;

            // CD-wide data is stored in a dummy track
            foreach (var command in parse_tree.data.commands) {
                if (!this.parse_node(command))
                    throw new ParseError.INVALID("Unhandled command '%s'",
                        command.command.to_string());
                if (command.command == Token.Command.PERFORMER)
                    default_performer_node = command;
            }

            // start iterating from the first 'real' track
            foreach (var track_token in parse_tree.next) {
                // track info is stored in the first command
                var track = new Track(this, track_token.commands.data);

                // skip track info
                foreach (var command in track_token.commands.next)
                    if (!track.parse_node(command))
                        throw new ParseError.INVALID(
                            "Unhandled command '%s'",
                            command.command.to_string());

                if (track.performer == null
                        && default_performer_node != null)
                    track.values.set((!) default_performer_node);

                this._tracks += track;
            }
        }

        internal Sheet() {}
    }
}
