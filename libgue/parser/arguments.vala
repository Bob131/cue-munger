internal enum IndexType {
    PREGAP,
    SONG_START
}

internal struct Timestamp {
    uint minutes;
    uint seconds;
    uint frames;
}

internal class Arguments : Node {
    public int length {get {return children.length;}}

    public override void validate() throws Gue.ParseError {
        if (!(parent is Command))
            error("Arguments must be children of commands");

        foreach (var child in children)
            if (!(child is Argument))
                error("Argument container cannot contain non-arguments",
                    child.location);

        base.validate();
    }
}

internal class Argument : Node {
    public string @value = "";

    public override void validate() throws Gue.ParseError {
        if (!(parent is Arguments))
            error("Argument must be in arguments container");

        if (children.length != 0)
            error("Unexpected children");

        if (@value.length < 1)
            error("Empty argument");

        base.validate();
    }

    public Argument(owned string input) {
        if (input[0] == '"' && input[input.length - 1] == '"')
            input = input[1 : input.length - 1];
        @value = input;
    }
}

internal class BarcodeArgument : Argument {
    public override void validate() throws Gue.ParseError {
        base.validate();

        if (@value.length != 13)
            error(@"Barcode '$value' must be 13 characters long");

        foreach (var @char in @value.to_utf8())
            if (!@char.isdigit())
                error(@"Invalid character '$char' in barcode '$value'");
    }

    public BarcodeArgument(owned string input) {
        base(input);
    }
}

internal class FileTypeArgument : Argument {
    public override void validate() throws Gue.ParseError {
        base.validate();

        switch (@value) {
            case "WAVE":
            case "MP3":
                break;
            default:
                error(@"Unknown file type '$value'");
                break;
        }
    }

    public FileTypeArgument(owned string input) {
        base(input);
    }
}

internal class IndexArgument : Argument {
    public IndexType index_type {get {
        int64 ret;
        return_val_if_fail(int64.try_parse(@value, out ret)
            && IndexType.PREGAP <= ret <= IndexType.SONG_START, -1);
        return (IndexType) ret;
    }}

    public override void validate() throws Gue.ParseError {
        base.validate();

        if (index_type == -1)
            error(@"Index value '$value' is not supported");
    }

    public IndexArgument(owned string input) {
        base(input);
    }
}

internal class TimestampArgument : Argument {
    public Timestamp timestamp {owned get {
        Timestamp ret = {};
        @value.scanf("%02d:%02d:%02d", out ret.minutes, out ret.seconds,
            out ret.frames);
        return ret;
    }}

    public override void validate() throws Gue.ParseError {
        base.validate();

        if (@value.length != 8)
            error("Invalid timestamp: must be eight characters");

        for (var i = 0; i < 8; i++)
            switch (i) {
                case 2:
                case 5:
                    if (@value[i] != ':')
                        error("Invalid timestamp: expected colon",
                            location + i);
                    break;
                default:
                    if (!@value[i].isdigit())
                        error("Invalid timestamp: expected digit",
                            location + i);
                    break;
            }

        var test = timestamp;
        if (test.seconds >= 60)
            error("Cannot have more than sixty seconds in a minute");
        if (test.frames >= 75)
            error("Cannot have more than seventy-five frames in a second");
    }

    public TimestampArgument(owned string input) {
        base(input);
    }
}

internal class IsrcArgument : Argument {
    public override void validate() throws Gue.ParseError {
        base.validate();

        if (@value.length != 12)
            error("ISRC identifier must be twelve characters");

        for (var i = 0; i < 12; i++)
            switch (i) {
                case 0:
                case 1:
                    if (!@value[i].isalpha())
                        error("Invalid ISRC: expected alphabetic character",
                            location + i);
                    break;
                case 2:
                case 3:
                case 4:
                    if (!@value[i].isalnum())
                        error("Invalid ISRC: expected alphanumeric character",
                            location + i);
                    break;
                default:
                    if (!@value[i].isdigit())
                        error("Invalid ISRC: expected digit", location + i);
                    break;
            }
    }

    public IsrcArgument(owned string input) {
        base(input);
    }
}

internal class TrackArgument : Argument {
    public int number {get {
        int ret;
        @value.scanf("%02d", out ret);
        return_val_if_fail(1 <= ret <= int.MAX, -1);
        return (int) ret;
    }}

    public override void validate() throws Gue.ParseError {
        base.validate();

        if (@value.length != 2)
            error("Track number must be two digits");

        if (number == -1)
            error(@"Invalid track number '$value'");
    }

    public TrackArgument(owned string input) {
        base(input);
    }
}
