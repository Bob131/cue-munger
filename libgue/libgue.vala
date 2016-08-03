namespace Gue {
    public errordomain ParseError {
        UNKNOWN,
        INVALID,
        EMPTY
    }

    public enum FileType {
        WAVE,
        MP3;

        internal static FileType from_string(string input) throws ParseError {
            var @enum = (EnumClass) typeof(FileType).class_ref();
            var type = @enum.get_value_by_nick(input.down());
            if (type == null)
                throw new Gue.ParseError.UNKNOWN("Unknown file type '%s'",
                    input);
            return (FileType) ((!) type).value;
        }
    }

    internal class StringValues {
        HashTable<Token.Command, string?> values =
            new HashTable<Token.Command, string?>(direct_hash, direct_equal);

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
            if (values.contains(command.command))
                throw new ParseError.INVALID("%s already set",
                    command.command.to_string());
            values.set(command.command, command.arguments.data);
            return true;
        }

        public unowned string? @get(Token.Command key) {
            return values.get(key);
        }
    }

    public abstract class Work : Object {
        internal StringValues values = new StringValues();

        Token.Command[] valid_keys = {Token.Command.TITLE,
            Token.Command.PERFORMER};
        public string? title {get {return values[Token.Command.TITLE];}}
        public string? performer {get {return values[Token.Command.PERFORMER];}}

        internal string[] _comments = {};
        public string[] comments {owned get {return _comments;}}

        internal bool parse_node(Node.Command command) throws ParseError {
            if (command.command == Token.Command.REM) {
                string?[]? words = {};
                foreach (var arg in command.arguments)
                    words += arg;
                _comments += string.joinv(" ", words);
                return true;
            }
            return values.set(command);
        }

        internal Work() {
            values.set_valid(valid_keys);
        }
    }

    public interface TrackContainer : Object {
        public abstract Track[] tracks {owned get;}
        internal abstract signal void add_track(Track track);
    }

    public class Track : Work {
        Token.Command[] valid_keys = {Token.Command.ISRC};
        public string? isrc {get {return this.values[Token.Command.ISRC];}}

        internal weak TrackContainer _parent;
        public weak TrackContainer parent {get {return _parent;}}

        private bool is_eac;

        internal int _number;
        public int number {get {return _number;}}

        internal float? _start_time = null;
        public float? start_time {get {return _start_time;}}

        internal float? _length = null;
        public float? length {get {return _length;}}

        internal new bool parse_node(Node.Command command) throws ParseError {
            if (command.command == Token.Command.INDEX) {
                if (command.arguments.length() != 2)
                    throw new ParseError.INVALID("INDEX command requires %s",
                        "two arguments");
                if (!is_eac &&
                        (command.arguments.data == "00" ||
                         command.arguments.data == "01")) {
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
                    if (parent.tracks.length > 0) {
                        var prev = parent.tracks[parent.tracks.length - 1];
                        if (prev.start_time != null && prev.length == null) {
                            prev._length = _start_time - prev.start_time;
                        }
                    }
                }
                return true;
            }
            return base.parse_node(command);
        }

        internal Track(TrackContainer parent, bool is_eac, Node.Command track)
            requires (track.command == Token.Command.TRACK)
        {
            this.values.set_valid(valid_keys);
            _parent = parent;
            this.is_eac = is_eac;
            _number = int.parse(track.arguments.data);
        }
    }

    // FILE can only contain TRACK commands, so don't inherit from Work
    public class File : Object, TrackContainer {
        private Track[] _tracks = {};
        public Track[] tracks {owned get {return _tracks;}}

        string _name;
        public string name {get {return _name;}}

        FileType _file_type;
        public FileType file_type {get {return _file_type;}}

        internal File(Node.Track track) throws ParseError
            requires (track.commands.length() == 1)
            requires (track.commands.data.command == Token.Command.FILE)
        {
            unowned SList<string> args = track.commands.data.arguments;
            _name = args.data;
            _file_type = FileType.from_string(args.next.data);
            this.add_track.connect((track) => {_tracks += track;});
        }
    }

    public class Sheet : Work, TrackContainer {
        Token.Command[] valid_keys = {Token.Command.CATALOG};
        public string? barcode {get {
            return this.values[Token.Command.CATALOG];
        }}

        internal bool _generated_by_eac = false;
        public bool generated_by_eac {get {return _generated_by_eac;}}

        File[] _files = {};
        public File[] files {owned get {return _files;}}

        Track[] _tracks = {};
        public Track[] tracks {owned get {return _tracks;}}

        public Sheet.parse_file(GLib.File file) throws Error {
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

            // CD-wide data is stored in a dummy node
            foreach (var command in parse_tree.data.tracks.data.commands) {
                if (!this.parse_node(command))
                    throw new ParseError.INVALID("Unhandled command '%s'",
                        command.command.to_string());
                if (command.command == Token.Command.PERFORMER)
                    default_performer_node = command;
            }

            foreach (var comment in this.comments)
                if (comment.has_prefix("COMMENT ExactAudioCopy")) {
                    warning("It appears this file was generated with %s",
                        "ExactAudioCopy. Some functionality has been disabled");
                    _generated_by_eac = true;
                    break;
                }

            this.add_track.connect((track) => {_tracks += track;});

            // start iterating from the first 'real' track
            foreach (var file_token in parse_tree.next) {
                TrackContainer file;
                if (generated_by_eac)
                    file = this;
                else {
                    // file info is stored in a dummy track
                    file = new File(file_token.tracks.data);
                    file.add_track.connect((track) => {_tracks += track;});
                }

                // skip file info
                foreach (var track_token in file_token.tracks.next) {
                    // track info is stored in the first command
                    var track = new Track(file, generated_by_eac,
                        track_token.commands.data);

                    // skip track info
                    foreach (var command in track_token.commands.next)
                        if (!track.parse_node(command))
                            throw new ParseError.INVALID(
                                "Unhandled command '%s'",
                                command.command.to_string());

                    if (track.performer == null
                            && default_performer_node != null)
                        track.values.set((!) default_performer_node);

                    file.add_track(track);
                }

                if (file is File)
                    _files += (File) file;
            }
        }

        internal Sheet() {}
    }
}
