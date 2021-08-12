#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;
use integer;

use Test::More;
use Chess::Position qw(:all);
use Chess::Position::Macro;

my ($pos, @moves, @expect);

$pos = Chess::Position->newFromFEN('8/3k4/8/8/8/8/4K3/8 w - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 8, 'number of moves lone white king');
@expect = sort qw(e2f2 e2f1 e2e1 e2d1 e2d2 e2d3 e2e3 e2f3);
is_deeply \@moves, \@expect, 'moves for lone white king';

$pos = Chess::Position->newFromFEN('8/3k4/8/8/8/8/4K3/8 b - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 8, 'number of moves lone black king');
@expect = sort qw(d7e7 d7e6 d7d6 d7c6 d7c7 d7c8 d7d8 d7e8);
is_deeply \@moves, \@expect, 'moves for lone black king';

done_testing;
