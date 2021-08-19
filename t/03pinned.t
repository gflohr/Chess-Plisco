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
use Chess::Position qw(:all);
use Chess::Position::Macro;
use Chess::Position::Move;

my ($pos, @moves, @expect);

my @tests = (
	{
		name => 'white rook pinned by rook on same file',
		move => 'e4g4',
		fen => '8/4r2k/8/8/4R3/8/4K3/8 w - - 0 1',
		pinned => 1,
	},
	{
		name => 'pinned white rook capturing black rook on same file',
		move => 'e4e7',
		fen => '8/4r2k/8/8/4R3/8/4K3/8 w - - 0 1',
		pinned => 0,
	},
	{
		name => 'pinned white rook moving on same file',
		move => 'e4e3',
		fen => '8/4r2k/8/8/4R3/8/4K3/8 w - - 0 1',
		pinned => 0,
	},
	{
		name => 'black rook pinned by queen on same rank',
		move => 'd3d6',
		fen => '8/8/7K/8/8/1k1r2Q1/8/8 b - - 0 1',
		pinned => 1,
	},
	{
		name => 'pinned black rook capturing white queen on same rank',
		move => 'd3g3',
		fen => '8/8/7K/8/8/1k1r2Q1/8/8 b - - 0 1',
		pinned => 0,
	},
	{
		name => 'pinned black rook moving on same rank',
		move => 'd3c3',
		fen => '8/8/7K/8/8/1k1r2Q1/8/8 b - - 0 1',
		pinned => 0,
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Position->new($test->{fen});
	my $move = Chess::Position::Move->new($test->{move}, $pos)->toInteger;

	if ($test->{pinned}) {
		ok $pos->pinned($move), $test->{name};
	} else {
		ok !$pos->pinned($move), $test->{name};
	}
}

done_testing;
