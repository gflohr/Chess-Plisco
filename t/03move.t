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

my ($move, $from, $to);

$move = 0;
$from = cp_square_to_shift 'e2';
$to = cp_square_to_shift 'e4';
cp_move_set_from $move, $from;
cp_move_set_to $move, $to;
is(cp_move_from($move), $from, 'e2e4 from');
is(cp_move_to($move), $to, 'e2e4 to');
is(cp_move_promote($move), CP_NO_PIECE, 'e2e4 promote');
is($move, (11 << 6) | 27, 'e2e4 as integer');

$DB::single = 1;
$move = 0;
$from = cp_square_to_shift 'd2';
$to = cp_square_to_shift 'e1';
cp_move_set_from $move, $from;
cp_move_set_to $move, $to;
cp_move_set_promote $move, CP_QUEEN;
is(cp_move_from($move), $from, 'd2e1q from');
is(cp_move_to($move), $to, 'd2e1q to');
is(cp_move_promote($move), CP_QUEEN, 'd2e1q promote');
is($move, (12 << 6) | 3 | (CP_QUEEN << 13), 'd2e1q as integer');

done_testing;
