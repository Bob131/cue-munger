namespace Gue {
    public errordomain ParseError {
        UNKNOWN,
        INVALID,
        EMPTY,
        UNSUPPORTED
    }

    public enum FileType {
        WAVE,
        MP3;

        internal static FileType from_string(string input) {
            var @enum = (EnumClass) typeof(FileType).class_ref();
            var type = @enum.get_value_by_nick(input.down());
            return_if_fail(type != null);
            return (FileType) ((!) type).value;
        }
    }

    public abstract class Work : Object {
        internal string? _title = null;
        public string? title {get {return _title;}}

        internal string? _performer = null;
        public string? performer {get {return _performer;}}

        internal Work() {}
    }

    public class Track : Work {
        internal string? _isrc = null;
        public string? isrc {get {return _isrc;}}

        internal weak TrackContainer _parent;
        public weak TrackContainer parent {get {return _parent;}}

        internal int _number;
        public int number {get {return _number;}}

        internal float? _start_time = null;
        public float? start_time {get {return _start_time;}}

        internal float? _length = null;
        public float? length {get {return _length;}}

        internal Track() {}
    }

    public interface TrackContainer : Object {
        public abstract Track[] tracks {get;}
        internal abstract signal void add_track(Track track);
    }

    public class File : Object, TrackContainer {
        private Track[] _tracks = {};
        public Track[] tracks {get {return _tracks;}}

        string _name;
        public string name {get {return _name;}}

        FileType _file_type;
        public FileType file_type {get {return _file_type;}}

        internal File(FileCommand file) {
            _name = file.file_name.@value;
            _file_type = FileType.from_string(file.file_type.@value);
            this.add_track.connect((track) => _tracks += track);
        }
    }

    public class Sheet : Work, TrackContainer {
        internal string? _barcode = null;
        public string? barcode {get {return _barcode;}}

        internal bool _generated_by_eac = false;
        public bool generated_by_eac {get {return _generated_by_eac;}}

        File[] _files = {};
        public File[] files {get {return _files;}}

        Track[] _tracks = {};
        public Track[] tracks {get {return _tracks;}}

        string[] _comments = {};
        public string[] comments {get {return _comments;}}

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

        public Sheet.parse_data(uint8[] data) throws ParseError
            requires (data.length != -1)
        {
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

            // the lexer won't fully lex a line unless it ends with \r or \n
            if (!(copy[copy.length - 1].to_string() in "\r\n"))
                copy += "\n";

            var parse_tree = lex_cue((!) copy);

            this.add_track.connect((track) => _tracks += track);

            foreach (var node in parse_tree.children) {
                if (node is RemarkCommand)
                    _comments += ((RemarkCommand) node).remark;

                else if (node is PerformerCommand)
                    _performer = ((PerformerCommand) node).performer.@value;

                else if (node is CatalogCommand)
                    _barcode = ((CatalogCommand) node).barcode.@value;

                else if (node is TitleCommand)
                    _title = ((TitleCommand) node).title.@value;

                else if (node is FileCommand) {
                    var file_node = (FileCommand) node;
                    TrackContainer container;

                    if (generated_by_eac)
                        container = this;
                    else {
                        file_node.non_eac_validate();
                        container = new File(file_node);
                        container.add_track.connect(
                            (track) => _tracks += track);
                    }

                    foreach (var track_node in file_node.tracks) {
                        var track = new Track();
                        track._parent = container;
                        track._number = track_node.track.number;
                        track._performer = _performer;

                        var seen_index = -1;

                        foreach (var track_child in track_node.children) {
                            if (track_child is TitleCommand)
                                track._title =
                                    ((TitleCommand) track_child).title.@value;
                            else if (track_child is PerformerCommand)
                                track._performer = ((PerformerCommand) track_child)
                                    .performer.@value;
                            else if (track_child is IsrcCommand)
                                track._isrc =
                                    ((IsrcCommand) track_child).isrc.@value;
                            else if (track_child is IndexCommand) {
                                var index = (IndexCommand) track_child;

                                if ((int) index.index.index_type < seen_index)
                                    continue;
                                seen_index = index.index.index_type;

                                var timestamp = index.timestamp.timestamp;
                                var start_time = (timestamp.minutes * 60)
                                    + timestamp.seconds
                                    + (timestamp.frames / 75f);

                                if (start_time == 0
                                        && track._start_time != null)
                                    continue;

                                track._start_time = start_time;

                                if (container.tracks.length > 0) {
                                    var prev_track = container
                                        .tracks[container.tracks.length - 1];
                                    if (prev_track._length == null)
                                        prev_track._length = track._start_time
                                            - prev_track._start_time;

                                // This is to try and make sense of EAC's
                                // jumbled-up INDEX commands
                                } else if (start_time > 0) {
                                    if (_tracks.length > 0) {
                                        var prev_track =
                                            _tracks[_tracks.length - 1];
                                        if (prev_track._length == null)
                                            prev_track._length = start_time;
                                    }

                                    track._start_time = null;
                                }
                            }
                        }

                        container.add_track(track);
                    }

                    if (container is File)
                        _files += (File) container;

                } else
                    assert_not_reached();
            }

            if (_tracks.length == 0)
                throw new ParseError.EMPTY("Cue sheet appears to be empty");
        }

        internal Sheet() {}
    }
}
