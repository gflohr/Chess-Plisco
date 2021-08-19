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
		name => 'e4 after initial',
		before => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
		move => 'e2e4',
		after => 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
	},
	{
		name => 'c5 Sicilian defense',
		before => 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
		move => 'c7c5',
		after => 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2',
	},
	{
		name => '2. Nf3 Sicilian defense',
		before => 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2',
		move => 'g1f3',
		after => 'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2',
	},
	{
		name => 'pawn captures knight exd5',
		before => '7k/8/8/3n4/4P3/8/8/7K w - - 0 1',
		move => 'e4d5',
		after => '7k/8/8/3P4/8/8/8/7K b - - 0 1',
	},
	{
		name => 'white captures en passant',
		before => '7k/8/8/3Pp3/8/8/8/7K w - d6 0 1',
		move => 'd5e6',
		after => '7k/8/4P3/8/8/8/8/7K b - - 0 1',
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Position->new($test->{before});
	ok $pos, $test->{name};
	my $move = Chess::Position::Move->new($test->{move}, $pos);
	my $undoInfo = $pos->doMove($move->toInteger);
	if ($test->{after}) {
		ok $undoInfo, "$test->{name}: move should be legal";
		is $pos->toFEN, $test->{after}, "$test->{name}";
	} else {
		ok !$undoInfo, "$test->{name}: move should not be legal";
	}
}

done_testing;
