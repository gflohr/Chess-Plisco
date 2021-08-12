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
use Chess::Position::Macro;

my ($bitboard, $count);

$bitboard = 0x88;
cp_bb_popcount $bitboard, $count;
is $count, 2, 'popcount 0x88';
is $bitboard, 0x88, 'popcount 0x88';

$bitboard = 0xffff_ffff_ffff_ffff;
cp_bb_popcount $bitboard, $count;
is $count, 64, 'popcount 0xffff_ffff_ffff_ffff';
is $bitboard, 0xffff_ffff_ffff_ffff, 'popcount 0xffff_ffff_ffff_ffff';

$bitboard = 0x1;
is(cp_bb_clear_but_least_set($bitboard), 0x1,
	"cp_bb_clear_but_least_set($bitboard)");

$bitboard = 0x3;
is(cp_bb_clear_but_least_set($bitboard), 0x1,
	"cp_bb_clear_but_least_set($bitboard)");

$bitboard = 0x7;
is(cp_bb_clear_but_least_set($bitboard), 0x1,
	"cp_bb_clear_but_least_set($bitboard)");

$bitboard = 0xf;
is(cp_bb_clear_but_least_set($bitboard), 0x1,
	"cp_bb_clear_but_least_set($bitboard)");

$bitboard = 0x7fff_ffff_ffff_ffff;
is(cp_bb_clear_but_least_set($bitboard), 0x1,
	"cp_bb_clear_but_least_set($bitboard)");

$bitboard = 0x8fff_ffff_ffff_ffff;
is(cp_bb_clear_but_least_set($bitboard), 0x1,
	"cp_bb_clear_but_least_set($bitboard)");

$bitboard = 0xffff_ffff_ffff_ffff;
is(cp_bb_clear_but_least_set($bitboard), 0x1,
	"cp_bb_clear_but_least_set($bitboard)");

$bitboard = 0x2;
is(cp_bb_count_trailing_zbits($bitboard), 1,
	"cp_bb_count_trailing_zbits($bitboard)");

$bitboard = 0x8000;
is(cp_bb_count_trailing_zbits($bitboard), 15,
	"cp_bb_count_trailing_zbits($bitboard)");

$bitboard = 0x8000_0000_0000_0000;
is(cp_bb_count_trailing_zbits($bitboard), 63,
	"cp_bb_count_trailing_zbits($bitboard)");

$bitboard = 0x1;
is(cp_bb_count_trailing_zbits($bitboard), 0,
	"cp_bb_count_trailing_zbits($bitboard)");

$bitboard = 0x3;
is(cp_bb_clear_least_set($bitboard), 0x2,
	"cp_bb_clear_least_set($bitboard)");

done_testing;
