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
);

plan tests => 3 * @tests;

foreach my $test (@tests) {
	my $pos = Chess::Position->new($test->{fen});
	ok $pos, "valid FEN $test->{fen}";
	my $move = $pos->parseMove($test->{move});
	ok $move, "valid move $test->{move}";
	is $pos->SAN($move), $test->{san}, "$test->{move} -> $test->{san}";
}