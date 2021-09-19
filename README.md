# Chess-Plisco

Chess::Plisco is a representation of a chess position in Perl.  It also
contains a UCI compatible chess engine.

It only works with Perl versions that are compiled with support for 64
bit integers!

It is currently work in progress.

## Installation

Apart from Perl (which ships with your operating system unless you use
MS-DOS aka MS Windows), the software has little dependencies:

- [PPI](https://github.com/Perl-Critic/PPI)
- [Locale::TextDomain](https://github.com/gflohr/libintl-perl) from [libintl-perl](http://www.guido-flohr.net/en/projects/#libintl-perl)

Probably both dependencies are available for your system.  Search your package
manager for "PPI" and "libintl-perl".

Alternatively, install the command "cpanm" and do:

```shell
$ cpanm PPI::Document Locale::TextDomain
```

The software itself is built and installed with the usual commands:

```shell
$ perl Makefile.PL
$ make
$ make install
```

## Library

See the [tutorial](lib/Chess/Plisco/Tutorial.pod) for a gentle introduction
to the library.  When installed, you can also try the command
`perldoc Chess::Plisco::Tutorial`.

Reference documentation is available for
[Chess::Plisco](lib/Chess/Plisco.pod) (`perldoc Chess::Plisco`)
and
[Chess::Pllisco::Macro](lib/Chess/Plisco/Macro.pod)
(`perldoc Chess::Plisco::Macro`).

## Engine

### Running the Engine

The chess engine is started with the command "plisco". You can also run it
from inside the repository like this:

```shell
$ perl -Ilib bin/plisco
```

The engine needs several seconds to come up because the source code of the
engine and the library are parsed and the macros contained expanded.

### Graphical User Interfaces

Like almost all chess engines, plisco does not come with a graphical user
interface.  Try using one of these:

* [Cute Chess](https://cutechess.com/) (Linux, MacOS, and Windows)
* [Banksia GUI](https://banksiagui.com/) (Linux, MacOS, and Windows)
* [Arena](http://www.playwitharena.de/) (Linux, Windows)

## Copryight

Copyright (C) 2021, Guido Flohr, guido.flohr@cantanea.com, all rights reserved.
