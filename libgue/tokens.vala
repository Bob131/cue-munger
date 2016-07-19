// use classes instead of namespaces because vala doens't support private
// namespaces

internal class Token {
    public enum Command {
        CATALOG,
        INDEX,
        ISRC,
        PERFORMER,
        REM,
        TITLE,
        TRACK;

        public static Command from_string(string input) throws Gue.ParseError {
            var @enum = (EnumClass) typeof(Command).class_ref();
            var cmd = @enum.get_value_by_nick(input.down());
            if (cmd == null)
                throw new Gue.ParseError.UNKNOWN("Unknown command '%s'",
                    input);
            return (Command) ((!) cmd).value;
        }
    }
}

internal class Node {
    public class Command {
        public Token.Command command;
        public SList<string> arguments;

        public Command(Token.Command command) {
            this.command = command;
        }
    }

    public class Track {
        public SList<Command> commands;
    }
}
