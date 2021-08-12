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

$pos = Chess::Position->new('8/3k4/8/8/8/8/4K3/8 w - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 8, 'number of moves lone white king');
@expect = sort qw(e2f2 e2f1 e2e1 e2d1 e2d2 e2d3 e2e3 e2f3);
is_deeply \@moves, \@expect, 'moves for lone white king';

$pos = Chess::Position->new('8/3k4/8/8/8/8/4K3/8 b - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 8, 'number of moves lone black king');
@expect = sort qw(d7e7 d7e6 d7d6 d7c6 d7c7 d7c8 d7d8 d7e8);
is_deeply \@moves, \@expect, 'moves for lone black king';

$pos = Chess::Position->new('8/3k4/8/8/8/8/8/7K w - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 3, 'number of moves lone white king on h1');
@expect = sort qw(h1g1 h1g2 h1h2);
is_deeply \@moves, \@expect, 'moves for lone white king on h1';

$pos = Chess::Position->new('k7/8/8/8/8/8/3K4/8 b - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 3, 'number of moves lone black king on a8');
@expect = sort qw(a8b8 a8b7 a8a7);
is_deeply \@moves, \@expect, 'moves for lone black king on a8';

$pos = Chess::Position->new('3k4/8/8/8/8/8/8/4K3 w - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 5, 'number of moves king on 1st rank');
@expect = sort qw(e1d1 e1d2 e1e2 e1f2 e1f1);
is_deeply \@moves, \@expect, 'moves king on 1st rank';

$pos = Chess::Position->new('3k4/8/8/8/8/8/8/4K3 b - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 5, 'number of moves king on 8th rank');
@expect = sort qw(d8e8 d8e7 d8d7 d8c7 d8c8);
is_deeply \@moves, \@expect, 'moves king on 8th rank';

$pos = Chess::Position->new('8/8/k7/8/8/7K/8/8 w - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 5, 'number of moves king on h file');
@expect = sort qw(h3h2 h3g2 h3g3 h3g4 h3h4);
is_deeply \@moves, \@expect, 'moves king on h file';

$pos = Chess::Position->new('8/8/k7/8/8/7K/8/8 b - - 0 1');
@moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
is(scalar @moves, 5, 'number of moves king on h file');
@expect = sort qw(a6b6 a6b5 a6a5 a6a7 a6b7);
is_deeply \@moves, \@expect, 'moves king on h file';

done_testing;
