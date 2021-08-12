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
use Chess::Position qw(:all);
use Chess::Position::Macro;

my ($move, $from, $to);

$move = 0;
$from = cp_square_to_shift 'e2';
$to = cp_square_to_shift 'e4';
cp_move_set_from $move, $from;
cp_move_set_to $move, $to;
is(cp_move_coordinate_notation($move), 'e2e4', 'e2e4');

$move = 0;
$from = cp_square_to_shift 'd7';
$to = cp_square_to_shift 'e8';
cp_move_set_from $move, $from;
cp_move_set_to $move, $to;
cp_move_set_promote $move, CP_PIECE_CHARS->[CP_BLACK]->[CP_QUEEN];
is(cp_move_coordinate_notation($move), 'd7e8q', 'd7e8q');

done_testing;
