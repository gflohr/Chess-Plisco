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

use Test::More tests => 12 * 64;
use Chess::Position qw(:all);
use Chess::Position::Macro;

# The array elements are:
#
# - square
# - file (0 .. 7)
# - rank (0 .. 7)
# - shift (0 .. 63)
my @tests = (
	# 1st rank.
	['a1', 0, 0, 7],
	['b1', 1, 0, 6],
	['c1', 2, 0, 5],
	['d1', 3, 0, 4],
	['e1', 4, 0, 3],
	['f1', 5, 0, 2],
	['g1', 6, 0, 1],
	['h1', 7, 0, 0],
	# 2st rank.
	['a2', 0, 1, 15],
	['b2', 1, 1, 14],
	['c2', 2, 1, 13],
	['d2', 3, 1, 12],
	['e2', 4, 1, 11],
	['f2', 5, 1, 10],
	['g2', 6, 1,  9],
	['h2', 7, 1,  8],
	# 3rd rank.
	['a3', 0, 2, 23],
	['b3', 1, 2, 22],
	['c3', 2, 2, 21],
	['d3', 3, 2, 20],
	['e3', 4, 2, 19],
	['f3', 5, 2, 18],
	['g3', 6, 2, 17],
	['h3', 7, 2, 16],
	# 4th rank.
	['a4', 0, 3, 31],
	['b4', 1, 3, 30],
	['c4', 2, 3, 29],
	['d4', 3, 3, 28],
	['e4', 4, 3, 27],
	['f4', 5, 3, 26],
	['g4', 6, 3, 25],
	['h4', 7, 3, 24],
	# 5th rank.
	['a5', 0, 4, 39],
	['b5', 1, 4, 38],
	['c5', 2, 4, 37],
	['d5', 3, 4, 36],
	['e5', 4, 4, 35],
	['f5', 5, 4, 34],
	['g5', 6, 4, 33],
	['h5', 7, 4, 32],
	# 6th rank.
	['a6', 0, 5, 47],
	['b6', 1, 5, 46],
	['c6', 2, 5, 45],
	['d6', 3, 5, 44],
	['e6', 4, 5, 43],
	['f6', 5, 5, 42],
	['g6', 6, 5, 41],
	['h6', 7, 5, 40],
	# 7th rank.
	['a7', 0, 6, 55],
	['b7', 1, 6, 54],
	['c7', 2, 6, 53],
	['d7', 3, 6, 52],
	['e7', 4, 6, 51],
	['f7', 5, 6, 50],
	['g7', 6, 6, 49],
	['h7', 7, 6, 48],
	# 8th rank.
	['a8', 0, 7, 63],
	['b8', 1, 7, 62],
	['c8', 2, 7, 61],
	['d8', 3, 7, 60],
	['e8', 4, 7, 59],
	['f8', 5, 7, 58],
	['g8', 6, 7, 57],
	['h8', 7, 7, 56],
);

my $class = 'Chess::Position';
foreach my $test (@tests) {
	my ($square, $file, $rank, $shift) = @$test;

	# Methods.
	is $class->shiftToSquare($shift), $square,
		"shiftToSquare $square";
	is $class->squareToShift($square), $shift,
		"squareToShift $square";
	is $class->coordinatesToSquare($file, $rank), $square,
		"coordinatesToSquare $square";
	is $class->coordinatesToShift($file, $rank), $shift,
		"coordinatesToShift $square";
	is_deeply [$class->shiftToCoordinates($shift)], [$file, $rank],
		"shiftToCoordinates $shift";
	is_deeply [$class->squareToCoordinates($square)], [$file, $rank],
		"squareToCoordinates $shift";
	
	# Macros.
	is(cp_shift_to_square($shift), $square,
		"cp_shift_to_square $square");
	is(cp_square_to_shift($square), $shift,
		"cp_square_to_shift $square");
	is(cp_coords_to_square($file, $rank), $square,
		"cp_coords_to_square $square");
	is(cp_coords_to_shift($file, $rank), $shift,
		"cp_coords_to_shift $square");
	is_deeply([cp_shift_to_coords($shift)], [$file, $rank],
		"cp_shift_to_coords $shift");
	is_deeply([cp_square_to_coords($square)], [$file, $rank],
		"cp_square_to_coords $shift");
}
