#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More;
use Chess::Position;

my $pos = Chess::Position->new;

ok $pos, 'created';

my $got = $pos->toFEN;
my $initial = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
my $wanted = $initial;

is $got, $wanted, 'FEN initial position';
is "$pos", $wanted, 'FEN initial position stringified';

is_deeply(Chess::Position->newFromFEN($wanted), $pos, 'newFromFEN');

eval {
	Chess::Position->newFromFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w');
};
ok $@, "castling state required";

is(Chess::Position->newFromFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq')
   ->toFEN, $initial, 'defaults');

eval {
	Chess::Position->newFromFEN('rnbqkbnr/pppppppp/8/8/8/PPPPPPPP/RNBQKBNR w KQkq');
};
ok $@, "exactly 8 ranks";

eval {
	Chess::Position->newFromFEN('rnbqkbnr/pppppppp/8/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq');
};
ok $@, "exactly 8 ranks";

eval {
	Chess::Position->newFromFEN('rsbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq');
};
ok $@, "illegal character";

eval {
	Chess::Position->newFromFEN('rsbqkbnr/pppppppp/8/8/9/8/PPPPPPPP/RNBQKBNR w KQkq');
};
ok $@, "illegal number 9";

eval {
	Chess::Position->newFromFEN('rsbqkbnr/pppp0pppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq');
};
ok $@, "illegal number 0";

done_testing;
