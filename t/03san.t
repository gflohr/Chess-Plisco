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
use Chess::Position;

my @tests = (
	{
		fen => 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
		move => 'e1g1',
		san => 'O-O',
	},
	{
		fen => 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
		move => 'e1c1',
		san => 'O-O-O',
	},
	{
		fen => 'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1',
		move => 'e8g8',
		san => 'O-O',
	},
	{
		fen => 'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1',
		move => 'e8c8',
		san => 'O-O-O',
	},
	{
		fen => 'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1',
		move => 'e8e7',
		san => 'Ke7',
	},
	{
		fen => 'r6r/4k3/3R4/r6r/R6R/8/3RK3/R6R w - - 0 1',
		move => 'a1a3',
		san => 'R1a3',
	},
	{
		fen => 'r6r/4k3/3R4/r6r/R6R/8/3RK3/R6R w - - 0 1',
		move => 'a1c1',
		san => 'Rac1',
	},
	{
		fen => 'r6r/4k3/3R4/r6r/R6R/8/3RK3/R6R w - - 0 1',
		move => 'a4d4',
		san => 'Ra4d4',
	},
	{
		fen => 'r6r/4k3/3R4/r6r/R6R/8/3RK3/R6R w - - 0 1',
		move => 'd6e6',
		san => 'Re6+',
	},
	{
		fen => 'kr6/qn6/8/1N6/8/8/4K3/8 w - - 0 1',
		move => 'b5c7',
		san => 'Nc7#',
	},
);

plan tests => 3 * @tests;

foreach my $test (@tests) {
	my $pos = Chess::Position->new($test->{fen});
	ok $pos, "valid FEN $test->{fen}";
	my $move = $pos->parseMove($test->{move});
	ok $move, "valid move $test->{move}";
	is $pos->SAN($move), $test->{san}, "$test->{move} -> $test->{san}";
}