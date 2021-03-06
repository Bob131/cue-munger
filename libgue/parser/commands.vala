internal abstract class Command : Node {
    public Arguments args {get {
        return (Arguments) this.children[0];
    }}

    protected void expect_args(Type[] types) throws Gue.ParseError {
        if (args.length != types.length)
            error(@"Expected $(types.length) arguments, got $(args.length)");

        for (var i = 0; i < types.length; i++) {
            var type_name = types[i].name();
            if (type_name != "Argument")
                type_name = type_name.replace("Argument", "");
            type_name = type_name.down();

            if (Type.from_instance(args.children[i]) != types[i])
                error(@"Expected $type_name");
        }
    }

    protected void parent_check(Type target) throws Gue.ParseError {
        if (Type.from_instance(parent) != target) {
            var our_name = Type.from_instance(this).name();
            error(@"$our_name must belong to $(target.name())");
        }
    }

    public override void validate() throws Gue.ParseError {
        if (children.length < 1 || !(children[0] is Arguments))
            error("Missing arguments node");

        base.validate();
    }

    public Command() {
        this.add(new Arguments());
    }
}

internal abstract class ParentCommand : Command {}

// 'child command' meaning that it contains no children of its own;
// ParentCommand can also be a child
internal abstract class ChildCommand : Command {
    public override void validate() throws Gue.ParseError {
        if (children.length > 1)
            error("Child commands cannot have children");

        base.validate();
    }
}

internal class CatalogCommand : ChildCommand {
    public BarcodeArgument barcode {get {
        return (BarcodeArgument) args.children[0];
    }}

    public override void validate() throws Gue.ParseError {
        expect_args({typeof(BarcodeArgument)});
        parent_check(typeof(RootNode));
        base.validate();
    }
}

internal class FileCommand : ParentCommand {
    public Argument file_name {get {return (Argument) args.children[0];}}
    public FileTypeArgument file_type {get {
        return (FileTypeArgument) args.children[1];
    }}

    public TrackCommand[] tracks {get {
        return (TrackCommand[]) children[1 : children.length];
    }}

    public override void validate() throws Gue.ParseError {
        expect_args({typeof(Argument), typeof(FileTypeArgument)});
        parent_check(typeof(RootNode));

        if (children.length < 2)
            error("Each file needs at least one child track");

        foreach (var child in children[1 : children.length])
            if (!(child is TrackCommand)) {
                var child_type = Type.from_instance(child).name();
                error(@"Children of files must be tracks, not $child_type");
            }

        base.validate();
    }
}

internal class IndexCommand : ChildCommand {
    public IndexArgument index {get {return (IndexArgument) args.children[0];}}
    public TimestampArgument timestamp {get {
        return (TimestampArgument) args.children[1];
    }}

    public override void validate() throws Gue.ParseError {
        expect_args({typeof(IndexArgument), typeof(TimestampArgument)});
        parent_check(typeof(TrackCommand));
        base.validate();
    }
}

internal class IsrcCommand : ChildCommand {
    public IsrcArgument isrc {get {return (IsrcArgument) args.children[0];}}

    public override void validate() throws Gue.ParseError {
        expect_args({typeof(IsrcArgument)});
        parent_check(typeof(TrackCommand));
        base.validate();
    }
}

internal class PerformerCommand : ChildCommand {
    public Argument performer {get {return (Argument) args.children[0];}}

    public override void validate() throws Gue.ParseError {
        expect_args({typeof(Argument)});
        base.validate();
    }
}

internal class RemarkCommand : ChildCommand {
    public string remark = "";

    public override void validate() throws Gue.ParseError {
        if (remark.length == 0)
            throw new Gue.ParseError.UNSUPPORTED(
                "Zero-length remarks aren't supported");

        if (args.length != 0)
            error("Remarks cannot have arguments");

        base.validate();
    }

    public RemarkCommand(owned string input) {
        remark = input;
    }
}

internal class TitleCommand : ChildCommand {
    public Argument title {get {return (Argument) args.children[0];}}

    public override void validate() throws Gue.ParseError {
        expect_args({typeof(Argument)});
        base.validate();
    }
}

internal class TrackCommand : ParentCommand {
    public TrackArgument track {get {return (TrackArgument) args.children[0];}}

    public override void validate() throws Gue.ParseError {
        expect_args({typeof(TrackArgument)});
        base.validate();
    }
}
