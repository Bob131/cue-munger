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

    public abstract class Container : Object {
        internal string? _title = null;
        public string? title {get {return _title;}}

        internal string? _performer = null;
        public string? performer {get {return _performer;}}

        internal string[] _comments = {};
        public string[] comments {owned get {return _comments;}}

        internal bool parse_node(Node.Command command) throws ParseError {
            if (command.command == Token.Command.TITLE)
                if (_title == null) {
                    _title = command.arguments.data;
                    return true;
                } else
                    throw new ParseError.INVALID("TITLE already set");
            else if (command.command == Token.Command.PERFORMER)
                if (_performer == null) {
                    _performer = command.arguments.data;
                    return true;
                } else
                    throw new ParseError.INVALID("PERFORMER already set");
            else if (command.command == Token.Command.REM) {
                var comment = "";
                foreach (var arg in command.arguments)
                    comment += arg;
                _comments += comment;
                return true;
            }
            return false;
        }

        internal Container() {}
    }

    public class Track : Container {
        internal int _number;
        public int number {get {return _number;}}

        internal string? _isrc = null;
        public string? isrc {get {return _isrc;}}

        internal weak File _parent_file;
        public weak File parent_file {get {return _parent_file;}}

        internal new bool parse_node(Node.Command command)
            throws ParseError
        {
            if (base.parse_node(command))
                return true;

            if (command.command == Token.Command.ISRC)
                if (_isrc == null) {
                    _isrc = command.arguments.data;
                    return true;
                } else
                    throw new ParseError.INVALID("ISRC already set");
            else if (command.command == Token.Command.INDEX)
                return true;

            return false;
        }

        internal Track(File parent, Node.Command track)
            requires (track.command == Token.Command.TRACK)
        {
            _parent_file = parent;
            _number = int.parse(track.arguments.data);
        }
    }

    // FILE can only contain TRACK commands, so don't inherit from Container
    public class File : Object {
        internal Track[] _tracks = {};
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
        }
    }

    public class Sheet : Container {
        string? _barcode = null;
        public string? barcode {get {return _barcode;}}

        File[] _files = {};
        public File[] files {owned get {return _files;}}
        Track[] _tracks = {};
        public Track[] tracks {owned get {return _tracks;}}

        internal new void parse_node(Node.Command command) throws ParseError
            requires (command.command == Token.Command.CATALOG)
        {
            if (_barcode == null)
                _barcode = command.arguments.data;
            else
                throw new ParseError.INVALID("CATALOG already set");
        }

        public Sheet.parse_from_string(string data) throws ParseError {
            var parse_tree = lex_cue(data);
            if (parse_tree.length() == 1)
                throw new ParseError.EMPTY("Cue sheet appears to be empty");

            // CD-wide data is stored in a dummy node
            foreach (var command in parse_tree.data.tracks.data.commands)
                if (!base.parse_node(command))
                    this.parse_node(command);

            // skip CD-wide data
            foreach (var file_token in parse_tree.next) {
                // file info is stored in a dummy track
                var file = new File(file_token.tracks.data);

                // skip file info
                foreach (var track_token in file_token.tracks.next) {
                    // track info is stored in the first command
                    var track = new Track(file, track_token.commands.data);

                    // skip track info
                    foreach (var command in track_token.commands.next)
                        if (!track.parse_node(command))
                            this.parse_node(command);

                    file._tracks += (owned) track;
                    this._tracks += track;
                }

                _files += file;
            }
        }

        internal Sheet() {}
    }
}
