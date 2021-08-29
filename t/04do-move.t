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
use Time::HiRes qw(gettimeofday);

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
	{
		name => 'black captures en passant',
		before => '7k/8/8/8/3pP3/8/8/7K b - e3 0 1',
		move => 'd4e3',
		after => '7k/8/8/8/8/4p3/8/7K w - - 0 2',
	},
	{
		name => 'promotion',
		before => '7k/4P3/8/8/8/8/8/7K w - - 0 1',
		move => 'e7e8r',
		after => '4R2k/8/8/8/8/8/8/7K b - - 0 1',
	},
	{
		name => 'regular king move',
		before => 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
		move => 'e1d1',
		after => 'r3k2r/8/8/8/8/8/8/R2K3R b kq - 0 1',
	},
	{
		name => 'white king-side castling',
		before => 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
		move => 'e1g1',
		after => 'r3k2r/8/8/8/8/8/8/R4RK1 b kq - 0 1',
	},
	{
		name => 'white queen-side castling',
		before => 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
		move => 'e1c1',
		after => 'r3k2r/8/8/8/8/8/8/2KR3R b kq - 0 1',
	},
	{
		name => 'black king-side castling',
		before => 'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1',
		move => 'e8g8',
		after => 'r4rk1/8/8/8/8/8/8/R3K2R w KQ - 0 2',
	},
	{
		name => 'black queen-side castling',
		before => 'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1',
		move => 'e8c8',
		after => '2kr3r/8/8/8/8/8/8/R3K2R w KQ - 0 2',
	},
	# Bugs.
	{
		name => 'Rook move should not prevent castling on other side',
		before => 'rnbqkbnr/ppp1pppp/3p4/8/7P/8/PPPPPPP1/RNBQKBNR w KQkq - 0 2',
		move => 'h1h3',
		after => 'rnbqkbnr/ppp1pppp/3p4/8/7P/7R/PPPPPPP1/RNBQKBN1 b Qkq - 0 2',
	},
	{
		name => 'perft 4 bug 1',
		before => 'r1bqkbnr/pppppppp/2n5/1B6/8/4P3/PPPP1PPP/RNBQK1NR b KQkq - 2 2',
		move => 'c6d4',
		after => 'r1bqkbnr/pppppppp/8/1B6/3n4/4P3/PPPP1PPP/RNBQK1NR w KQkq - 3 3',
	},
	{
		name => 'queen move bug',
		before => 'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8',
		move => 'd1d6',
		after => 'rnbq1k1r/pp1Pbppp/2pQ4/8/2B5/8/PPP1NnPP/RNB1K2R b KQ - 2 8',
	},
	{
		name => 'capture queen giving check',
		before => 'r4rk1/p1ppqpbQ/bn2pnp1/3PN3/1p2P3/2N5/PPPBBPPP/R3K2R b KQ - 1 2',
		move => 'f6h7',
		after => 'r4rk1/p1ppqpbn/bn2p1p1/3PN3/1p2P3/2N5/PPPBBPPP/R3K2R w KQ - 0 3',
	},
	{
		name => 'capture pawn giving check en passant',
		before => '8/8/3p4/1Pp4r/1K3p2/6k1/4P1P1/1R6 w - c6 0 3',
		move => 'b5c6',
		after => '8/8/2Pp4/7r/1K3p2/6k1/4P1P1/1R6 b - - 0 3',
	},
);

foreach my $test (@tests) {
if ($test->{name} eq 'capture pawn giving check en passant') {
	$DB::single = 1;
}
	my $pos = Chess::Position->new($test->{before});
	my $move = Chess::Position::Move->new($test->{move}, $pos)->toInteger;
	my $copy = $pos->copy;
	my $undoInfo = $pos->doMove($move);
	ok $pos->consistent, "$test->{name}: position should be consistent after $test->{move}";
	if ($test->{after}) {
		ok $undoInfo, "$test->{name}: move should be legal" or next;
		is $pos->toFEN, $test->{after}, "$test->{name}: FEN should equal expected.";
		$pos->undoMove($move, $undoInfo);
		is $pos->toFEN, $test->{before}, "$test->{name}: undo $test->{move}";
		is_deeply $pos, $copy,
			"$test->{name}: undo $test->{move}, structures should not differ";
		ok $pos->consistent, "$test->{name}: position should be consistent after undo $test->{move}";
	} else {
		ok !$undoInfo, "$test->{name}: move should not be legal";
		is $pos->toFEN, $test->{before}, "$test->{name}: move should not modify";
		ok $pos->consistent, "$test->{name}: position should be consistent after illegal $test->{move}";
	}
}

done_testing;
