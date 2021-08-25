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
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);

use Chess::Position qw(:all);
use Chess::Position::Macro;

my @tests = (
	{
		name => 'Start position',
		perft => [20, 400, 8902, 197281, 4865609, 119060324, 3195901860],
	},
	{
		name => 'Kiwipete',
		fen => 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
		perft => [48, 2039, 97862, 4085603, 193690690],
	},
	{
		name => 'Discovered check',
		fen => '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -',
		perft => [14, 191, 2812, 43238, 674624, 11030083, 178633661, 3009794393],
	},
	{
		name => 'Chessprogramming.org Position 4',
		fen => 'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
		perft => [6, 264, 9467, 422333, 15833292, 706045033],
	},
	{
		name => 'Chessprogramming.org Position 4 Reversed',
		fen => 'r2q1rk1/pP1p2pp/Q4n2/bbp1p3/Np6/1B3NBn/pPPP1PPP/R3K2R b KQ - 0 1',
		perft => [6, 264, 9467, 422333, 15833292, 706045033],
	},
	{
		name => 'Chessprogramming.org Position 5',
		fen => 'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8',
		perft => [44, 1486, 62379, 2103487, 89941194],
	},
	{
		name => 'Steven Edwards Alternative (chessprogramming.org #6)',
		fen => 'r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10',
		perft => [46, 2079, 89890, 3894594, 164075551],
	},
	{
		name => 'Most Legal Moves (Nenad Petrovic 1964)',
		fen => 'R6R/3Q4/1Q4Q1/4Q3/2Q4Q/Q4Q2/pp1Q4/kBNN1KB1 w - - 1 1',
		perft => [218, 99, 19073, 85043, 13853661, 115892741],
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Position->new($test->{fen});
	my @perfts = @{$test->{perft}};

	my $started = [gettimeofday];
	for (my $depth = 1; $depth <= @perfts; ++$depth) {
		no integer;
		SKIP: {
			my $elapsed = tv_interval($started);
			if ($elapsed > 1) {
				my $skipped = @perfts - $depth;
				skip "set environment variable CP_STRESS_TEST to a truthy value to run all tests",
					$skipped;
			}
			my $expect = $perfts[$depth - 1];
			my $got = $pos->perft($depth);
			is $got, $expect, "perft depth $depth ($test->{name})";
		}
	}
}

done_testing;
