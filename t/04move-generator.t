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

my ($pos, @moves);

$pos = Chess::Position->newFromFEN('8/3k4/8/8/8/8/4K3/8 w - - 0 1');
@moves = $pos->pseudoLegalMoves;
is(scalar @moves, 8, 'lone white king');

$pos = Chess::Position->newFromFEN('8/3k4/8/8/8/8/4K3/8 b - - 0 1');
@moves = $pos->pseudoLegalMoves;
is(scalar @moves, 8, 'lone black king');

done_testing;
