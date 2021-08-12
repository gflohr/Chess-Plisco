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

done_testing;
