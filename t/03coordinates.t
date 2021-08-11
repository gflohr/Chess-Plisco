#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More tests => 64 * 6;
use Chess::Position::Macro;

my @squares;

my @data = (
	[h1 => 7, 0],
	[g1 => 6, 0],
	[f1 => 5, 0],
	[e1 => 4, 0],
	[d1 => 3, 0],
	[c1 => 2, 0],
	[b1 => 1, 0],
	[a1 => 0, 0],
	[h2 => 7, 1],
	[g2 => 6, 1],
	[f2 => 5, 1],
	[e2 => 4, 1],
	[d2 => 3, 1],
	[c2 => 2, 1],
	[b2 => 1, 1],
	[a2 => 0, 1],
	[h3 => 7, 2],
	[g3 => 6, 2],
	[f3 => 5, 2],
	[e3 => 4, 2],
	[d3 => 3, 2],
	[c3 => 2, 2],
	[b3 => 1, 2],
	[a3 => 0, 2],
	[h4 => 7, 3],
	[g4 => 6, 3],
	[f4 => 5, 3],
	[e4 => 4, 3],
	[d4 => 3, 3],
	[c4 => 2, 3],
	[b4 => 1, 3],
	[a4 => 0, 3],
	[h5 => 7, 4],
	[g5 => 6, 4],
	[f5 => 5, 4],
	[e5 => 4, 4],
	[d5 => 3, 4],
	[c5 => 2, 4],
	[b5 => 1, 4],
	[a5 => 0, 4],
	[h6 => 7, 5],
	[g6 => 6, 5],
	[f6 => 5, 5],
	[e6 => 4, 5],
	[d6 => 3, 5],
	[c6 => 2, 5],
	[b6 => 1, 5],
	[a6 => 0, 5],
	[h7 => 7, 6],
	[g7 => 6, 6],
	[f7 => 5, 6],
	[e7 => 4, 6],
	[d7 => 3, 6],
	[c7 => 2, 6],
	[b7 => 1, 6],
	[a7 => 0, 6],
	[h8 => 7, 7],
	[g8 => 6, 7],
	[f8 => 5, 7],
	[e8 => 4, 7],
	[d8 => 3, 7],
	[c8 => 2, 7],
	[b8 => 1, 7],
	[a8 => 0, 7],
);

for (my $shift = 0; $shift < 64; ++$shift) {
	my ($wsquare, $wfile, $wrank) = @{$data[$shift]};

	is(cp_coords_to_shift($wfile, $wrank), $shift,
		"cp_coords_to_shift($wfile, $wrank) != $shift");
}