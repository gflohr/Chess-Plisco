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

$pos = Chess::Position->new('6nK/6PP/8/3N4/8/8/8/k7 w - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 9, 'number of moves knight on d5');
@expect = sort qw(h8g8 d5e7 d5f6 d5f4 d5e3 d5c3 d5b4 d5b6 d5c7);
is_deeply \@moves, \@expect, 'moves knight on d5';

$pos = Chess::Position->new('6nK/6PP/8/8/6N1/8/8/k7 w - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 7, 'number of moves knight on g4');
@expect = sort qw(h8g8 g4h6 g4h2 g4f2 g4e3 g4e5 g4f6);
is_deeply \@moves, \@expect, 'moves knight on g4';

$pos = Chess::Position->new('6nK/6PP/8/8/7N/8/8/k7 w - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 5, 'number of moves knight on h4');
@expect = sort qw(h8g8 h4g2 h4f3 h4f5 h4g6);
is_deeply \@moves, \@expect, 'moves knight on h4';

$pos = Chess::Position->new('6nK/6PP/8/8/8/8/3N4/k7 w - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 7, 'number of moves knight on d2');
@expect = sort qw(h8g8 d2f1 d2b1 d2b3 d2c4 d2e4 d2f3);
is_deeply \@moves, \@expect, 'moves knight on d2';

$pos = Chess::Position->new('6nK/6PP/8/8/8/8/8/k2N4 w - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 5, 'number of moves knight on d1');
@expect = sort qw(h8g8 d1b2 d1c3 d1e3 d1f2);
is_deeply \@moves, \@expect, 'moves knight on d1';

done_testing;
