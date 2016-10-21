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
        public string? title {set; get;}
        public string? performer {set; get;}
    }

    public class Track : Work {
        public File parent {construct; get;}

        public string? isrc {set; get;}
        public double? start_time {set; get;}
        public int number {set; get;}

        internal double? _length = null;
        internal double? _tmp;
        public double? length {get {
            Track? next = null;
            var next_index = parent.tracks.index_of(this) + 1;
            if (parent.tracks.size > next_index)
                next = parent.tracks[next_index];

            if (_length == null && start_time != null && next != null
                && ((!) next).start_time != null)
            {
                _tmp = ((!) next).start_time - start_time;
                return _tmp;
            } else
                return _length;
        }}

        public Track(File parent, bool add = true) {
            Object(parent: parent);

            if (add) {
                parent.tracks.add(this);
                parent.parent.tracks.add(this);
            }

            this.notify["start-time"].connect(() => {
                if (parent.parent.eac_dirty) {
                    foreach (var track in parent.parent.tracks)
                        track._length = null;
                    parent.parent.eac_dirty = false;
                }
            });
        }
    }

    public class File : Object {
        public Sheet parent {construct; get;}

        public string name {set; get;}
        public FileType file_type {set; get;}

        public Gee.LinkedList<Track> tracks = new Gee.LinkedList<Track>();

        public File(Sheet parent, bool add = true) {
            Object(parent: parent);

            if (add)
                parent.files.add(this);
        }
    }

    public class Sheet : Work {
        public string? barcode {set; get;}

        public Gee.LinkedList<File> files = new Gee.LinkedList<File>();
        public Gee.LinkedList<string> comments = new Gee.LinkedList<string>();
        public Gee.LinkedList<unowned Track> tracks =
            new Gee.LinkedList<unowned Track>();

        // Tracks whether we've specified any track lengths due to special
        // handling of EAC-generated cue sheets
        internal bool eac_dirty = false;

        public string to_string() throws Gue.ParseError {
            var builder = new TreeBuilder("");

            if (title != null) {
                builder.add(new TitleCommand());
                builder.add(new Argument((!) title));
            }

            if (performer != null) {
                builder.add(new PerformerCommand());
                builder.add(new Argument((!) performer));
            }

            if (barcode != null) {
                builder.add(new CatalogCommand());
                builder.add(new BarcodeArgument((!) barcode));
            }

            foreach (var comment in comments)
                builder.add(new RemarkCommand(comment));

            foreach (var file in files) {
                builder.add(new FileCommand());
                builder.add(new Argument(file.name));

                var file_type = file.file_type.to_string();
                var split = file_type.split("_");
                file_type = split[split.length - 1];
                builder.add(new FileTypeArgument(file_type));

                foreach (var track in file.tracks) {
                    builder.add(new TrackCommand());
                    builder.add(
                        new TrackArgument(track.number.to_string("%02d")));

                    if (track.title != null) {
                        builder.add(new TitleCommand());
                        builder.add(new Argument((!) track.title));
                    }

                    if (track.performer != null
                        && track.performer != performer)
                    {
                        builder.add(new PerformerCommand());
                        builder.add(new Argument((!) track.performer));
                    }

                    if (track.isrc != null) {
                        builder.add(new IsrcCommand());
                        builder.add(new IsrcArgument((!) track.isrc));
                    }

                    if (track.start_time != null) {
                        builder.add(new IndexCommand());
                        builder.add(new IndexArgument("00"));

                        var start = (!) track.start_time;
                        int minutes, seconds, frames;
                        minutes = (int) Math.floor(start / 60);
                        seconds = (int) Math.floor(start % 60);
                        frames = (int) Math.round(
                            (start - Math.floor(start)) * 75);

                        var timestamp = "%02d:%02d:%02d".printf(minutes,
                            seconds, frames);
                        builder.add(new TimestampArgument(timestamp));
                    }
                }
            }

            var root = builder.end();
            return root.to_string();
        }

        public Sheet.parse_file(GLib.File file) throws Error {
            uint8[] data;
            file.load_contents(null, out data, null);
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

            foreach (var node in parse_tree.children) {
                if (node is RemarkCommand)
                    comments.add(((RemarkCommand) node).remark);

                else if (node is PerformerCommand)
                    performer = ((PerformerCommand) node).performer.@value;

                else if (node is CatalogCommand)
                    barcode = ((CatalogCommand) node).barcode.@value;

                else if (node is TitleCommand)
                    title = ((TitleCommand) node).title.@value;

                else if (node is FileCommand) {
                    var file_node = (FileCommand) node;
                    var file = new File(this, false);
                    file.name = file_node.file_name.@value;
                    file.file_type =
                        FileType.from_string(file_node.file_type.@value);

                    foreach (var track_node in file_node.tracks) {
                        var track = new Track(file, false);
                        track.number = track_node.track.number;
                        track.performer = performer;

                        var seen_index = -1;

                        foreach (var track_child in track_node.children) {
                            if (track_child is TitleCommand)
                                track.title =
                                    ((TitleCommand) track_child).title.@value;
                            else if (track_child is PerformerCommand)
                                track.performer = ((PerformerCommand) track_child)
                                    .performer.@value;
                            else if (track_child is IsrcCommand)
                                track.isrc =
                                    ((IsrcCommand) track_child).isrc.@value;
                            else if (track_child is IndexCommand) {
                                var index = (IndexCommand) track_child;

                                if ((int) index.index.index_type < seen_index)
                                    continue;
                                seen_index = index.index.index_type;

                                var timestamp = index.timestamp.timestamp;
                                var start_time = (timestamp.minutes * 60)
                                    + timestamp.seconds
                                    + (timestamp.frames / 75.0);

                                if (start_time == 0 && track.start_time != null)
                                    continue;

                                track.start_time = start_time;

                                // This is to try and make sense of EAC's
                                // jumbled-up INDEX commands
                                if (file.tracks.size == 0 && track.number != 1
                                    && start_time > 0)
                                {
                                    eac_dirty = true;

                                    if (tracks.size > 0) {
                                        var prev_track = tracks.last();
                                        if (prev_track.length == null)
                                            prev_track._length = start_time;
                                    }

                                    track.start_time = null;
                                }
                            }
                        }

                        file.tracks.add(track);
                        tracks.add(track);
                    }

                    files.add(file);

                } else
                    assert_not_reached();
            }

            if (tracks.size == 0)
                throw new ParseError.EMPTY("Cue sheet appears to be empty");
        }
    }
}
