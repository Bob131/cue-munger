errordomain MungeError {
    ERROR
}

abstract class BaseMunger : Object {
    public abstract string name {get;}
    public abstract string description {get;}

    public abstract string munge(Gue.Sheet cue_sheet) throws MungeError;
}

class CueMunger : Application {
    BaseMunger[] mungers = {
        new MusicBrainz()
    };

    string usage = "Usage: %s <munger> <file>\n<munger> is one of:\n%s\n";

    internal override int command_line(ApplicationCommandLine cmd) {
        var args = cmd.get_arguments();

        string?[]? munger_strings = {};
        foreach (var munger in mungers)
            munger_strings += @"  $(munger.name)\t$(munger.description)";
        usage = usage.printf(Path.get_basename(args[0]),
            string.joinv("\n", munger_strings));

        if (args.length == 1) {
            stderr.printf(usage);
            return 0;
        }
        if (args.length != 3) {
            stderr.printf("Error: You must specify a munger and a file path\n");
            stderr.printf("\n");
            stderr.printf(usage);
            return 1;
        }

        var munger_name = args[1].down();
        BaseMunger? munger = null;
        foreach (var m in mungers)
            if (m.name == munger_name) {
                munger = m;
                break;
            }
        if (munger == null) {
            stderr.printf("Error: Munger '%s' not found\n\n", munger_name);
            stderr.printf(usage);
            return 1;
        }

        Gue.Sheet cue_sheet;
        try {
            cue_sheet = new Gue.Sheet.parse_file(
                cmd.create_file_for_arg(args[2]));
        } catch (Error e) {
            stderr.printf("Failed to parse cue sheet: %s\n", e.message);
            return 1;
        }

        try {
            stdout.printf("%s\n", ((!) munger).munge(cue_sheet));
        } catch (MungeError e) {
            stderr.printf("Munging failed: %s\n", e.message);
            return 1;
        }

        return 0;
    }

    CueMunger() {
        Object(flags: ApplicationFlags.NON_UNIQUE
            |ApplicationFlags.HANDLES_COMMAND_LINE);
    }

    public static int main(string[] args) {
        Intl.setlocale(LocaleCategory.ALL, "");
        return new CueMunger().run(args);
    }
}
