internal abstract class Node {
    public Node[] children = {};

    public weak Node? parent = null;
    public weak Node? prev = null;
    public weak Node? next = null;

    public long location = 0;

    public void add(Node child)
        requires (child.parent == null)
    {
        child.parent = this;

        if (children.length > 0) {
            var prev = children[children.length - 1];
            child.prev = prev;
            prev.next = child;
        }

        children += child;
    }

    protected void error(string text, long location = ((Node) this).location)
        throws Gue.ParseError
    {
        var iter = this;
        while (!(iter is RootNode))
            iter = (!) iter.parent;
        var root = (RootNode) iter;

        throw new Gue.ParseError.INVALID(
            @"$text (at $(line_offset(location, root.data)))");
    }

    public virtual void validate() throws Gue.ParseError {
        if (!(this is RootNode) && parent == null)
            error("Node has no parent");

        var performer_seen = false,
            index_count = 0,
            title_seen = false,
            isrc_seen = false,
            cat_seen = false;

        foreach (var child in children) {
            if (child is PerformerCommand)
                if (performer_seen)
                    error("Performer already set", child.location);
                else
                    performer_seen = true;
            else if (child is IndexCommand)
                if (index_count >= 2)
                    error("Too many index commands", child.location);
                else
                    index_count++;
            else if (child is TitleCommand)
                if (title_seen)
                    error("Title already set", child.location);
                else
                    title_seen = true;
            else if (child is IsrcCommand)
                if (isrc_seen)
                    error("ISRC already set", child.location);
                else
                    isrc_seen = true;
            else if (child is CatalogCommand)
                if (cat_seen)
                    error("Catalog number already set", child.location);
                else
                    cat_seen = true;

            child.validate();
        }
    }
}

internal class RootNode : Node {
    public unowned string data;

    public override void validate() throws Gue.ParseError {
        foreach (var child in children)
            if (!(child is PerformerCommand || child is TitleCommand
                    || child is RemarkCommand || child is FileCommand
                    || child is CatalogCommand))
            {
                var child_name = Type.from_instance(child).name();
                error(@"$child_name not allowed as a child of the root node",
                    0);
            }

        if (parent != null)
            throw new Gue.ParseError.INVALID("Root node cannot have parent");

        base.validate();
    }

    string to_string_recurse(Command node, int indent) {
        if (node is RemarkCommand)
            return @"REM $(((RemarkCommand) node).remark)";

        var ret = "";

        for (var i = 0; i < indent * 4; i++)
            ret += " ";

        var type_name = Type.from_instance(node).name();
        type_name = type_name.replace("Command", "");
        ret += type_name.up();

        foreach (var arg in node.args.children) {
            var arg_string = ((Argument) arg).@value;

            if (Type.from_instance(arg) == typeof(Argument))
                arg_string = @"\"$arg_string\"";

            ret += @" $arg_string";
        }

        if (node is TrackCommand)
            ret += " AUDIO";

        foreach (var child in node.children) {
            if (!(child is Command))
                continue;
            ret += "\n";
            ret += to_string_recurse((Command) child, indent + 1);
        }

        return ret;
    }

    public string to_string() {
        var ret = "";

        foreach (var child in children) {
            ret += to_string_recurse((Command) child, 0);
            ret += "\n";
        }

        return ret;
    }

    public RootNode(string data) {
        this.data = data;
    }
}
