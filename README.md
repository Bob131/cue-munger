# cue-munger

cue-munger is a CLI application that aims to ease some of the pain of working
with [cue sheets][cue sheet wiki].

### Why?

Cue sheets are quite awkward to handle with the standard UNIX tools because of
their context-sensitive grammar; some lexical analysis is required to make sense
of the format. [Cuetools][cuetools github] already exists for this purpose, but
my experience with them is that they don't work very well: I rarely come across
cue sheets libcue will actually parse, and their odd behaviour makes usage a
frustrating experience. Anyway, reinventing the wheel is fun :)

With cue-munger, my approach has been founded on the recognition that processing
such highly-structured data is a poor fit for shell scripting. So instead of
creating a tool that delegates processing to others, it's more convenient to
have a tool that is super simple to extend with whatever processing
functionality you need.

cue-munger is written in [Vala][vala], and there are a couple of short steps
required to add a new munger:

 * Add a source file in `src/mungers/`, containing a class that inherits from
   `BaseMunger` (see `musicbrainz.vala` for a simple example).
 * Add your file to the sources list in `src/Makefile.am`.
 * Add your class to the `CueMunger.mungers` array in `cue-munge.vala`
 * Open a pull request!

Of course, Vala mightn't be your cup of tea. Since all the heavy lifting is done
by libgue (GObject libcue), it should be a cinch to use it from whatever
language you prefer with the [GObject Introspection][gi] bindings.

Please keep in mind that libgue is still new (and written by someone who is
still new, to lexical analysis in particular). It's likely chock full of bugs,
and the API will probably change pretty drastically in the near future (several
times). So, er...  don't use it in production, 'kay? :)

### Building

Pretty straight-forward, just your usual autotools setup:

```
    git clone https://github.com/Bob131/cue-munger
    cd cue-munger
    ./autogen.sh
    make && make install
```

You'll need GLib dev packages, [Ragel][ragel] and whatever package provides
`g-ir-compiler` on your system (`gobject-introspection-devel` on Fedora).


[cue sheet wiki]: https://en.wikipedia.org/wiki/Cue_sheet_(computing)
[cuetools github]: https://github.com/svend/cuetools
[vala]: https://wiki.gnome.org/Projects/Vala
[gi]: https://wiki.gnome.org/Projects/GObjectIntrospection
[ragel]: https://www.colm.net/open-source/ragel/
