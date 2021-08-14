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

my ($pos, @moves, @expect);

my @tests = (
	# Castlings.
	{
		name => 'white castlings',
		fen => 'r3k2r/p6p/p6p/8/8/P6P/P6P/R3K2R w KQkq - 0 1',
		moves => [qw(e1g1 e1c1 e1d1 e1d2 e1e2 e1f2 e1f1
			a3a4 h3h4 a1b1 a1c1 a1d1 h1g1 h1f1)],
	},
	{
		name => 'black castlings',
		fen => 'r3k2r/p6p/p6p/8/8/P6P/P6P/R3K2R b KQkq - 0 1',
		moves => [qw(e8g8 e8c8 e8d8 e8d7 e8e7 e8f7 e8f8
			a6a5 h6h5 a8b8 a8c8 a8d8 h8g8 h8f8)],
	},
	{
		name => 'lost white king-side castling',
		fen => 'r3k2r/p6p/p6p/8/8/P6P/P6P/R3K2R w Qkq - 0 1',
		moves => [qw(e1c1 e1d1 e1d2 e1e2 e1f2 e1f1
			a3a4 h3h4 a1b1 a1c1 a1d1 h1g1 h1f1)],
	},
	{
		name => 'lost black king-side castling',
		fen => 'r3k2r/p6p/p6p/8/8/P6P/P6P/R3K2R b KQq - 0 1',
		moves => [qw(e8c8 e8d8 e8d7 e8e7 e8f7 e8f8
			a6a5 h6h5 a8b8 a8c8 a8d8 h8g8 h8f8)],
	},
	{
		name => 'lost white queen-side castling',
		fen => 'r3k2r/p6p/p6p/8/8/P6P/P6P/R3K2R w Kkq - 0 1',
		moves => [qw(e1g1 e1d1 e1d2 e1e2 e1f2 e1f1
			a3a4 h3h4 a1b1 a1c1 a1d1 h1g1 h1f1)],
	},
	{
		name => 'lost black queen-side castling',
		fen => 'r3k2r/p6p/p6p/8/8/P6P/P6P/R3K2R b KQk - 0 1',
		moves => [qw(e8g8 e8d8 e8d7 e8e7 e8f7 e8f8
			a6a5 h6h5 a8b8 a8c8 a8d8 h8g8 h8f8)],
	},
	{
		name => 'white king blocked for king-side castling',
		fen => 'r3kn1r/p6p/p6p/8/8/P6P/P6P/R3KN1R w KQkq - 0 1',
		moves => [qw(e1c1 e1d1 e1d2 e1e2 e1f2
			a3a4 h3h4 a1b1 a1c1 a1d1 h1g1
			f1d2 f1e3 f1g3)],
	},
	{
		name => 'black king blocked for king-side castling',
		fen => 'r3kn1r/p6p/p6p/8/8/P6P/P6P/R3KN1R b KQkq - 0 1',
		moves => [qw(e8c8 e8d8 e8d7 e8e7 e8f7
			a6a5 h6h5 a8b8 a8c8 a8d8 h8g8
			f8d7 f8e6 f8g6)],
	},
	{
		name => 'white king blocked for queen-side castling',
		fen => 'r2nk2r/p6p/p6p/8/8/P6P/P6P/R2NK2R w KQkq - 0 1',
		moves => [qw(e1g1 e1d2 e1e2 e1f2 e1f1
			a3a4 h3h4 a1b1 a1c1 h1g1 h1f1
			d1b2 d1c3 d1e3 d1f2)],
	},
	{
		name => 'black king blocked for queen-side castling',
		fen => 'r2nk2r/p6p/p6p/8/8/P6P/P6P/R2NK2R b KQkq - 0 1',
		moves => [qw(e8g8 e8d7 e8e7 e8f7 e8f8
			a6a5 h6h5 a8b8 a8c8 h8g8 h8f8
			d8b7 d8c6 d8e6 d8f7)],
	},
	{
		name => 'white rook blocked for queen-side castling',
		fen => 'rn2k2r/p6p/p6p/8/8/P6P/P6P/RN2K2R w KQkq - 0 1',
		moves => [qw(e1g1 e1d2 e1e2 e1f2 e1f1
			a3a4 h3h4 h1g1 h1f1
			b1c3 b1d2)],
	},
	{
		name => 'black rook blocked for queen-side castling',
		fen => 'rn2k2r/p6p/p6p/8/8/P6P/P6P/RN2K2R b KQkq - 0 1',
		moves => [qw(e8g8 e8d7 e8e7 e8f7 e8f8
			a6a5 h6h5 h8g8 h8f8
			b8c6 b8d7)],
	},
	# King moves.
	{
		name => 'lone white king on e2',
		fen => '8/3k4/8/8/8/8/4K3/8 w - - 0 1',
		moves => [qw(e2f2 e2f1 e2e1 e2d1 e2d2 e2d3 e2e3 e2f3)],
	},
	{
		name => 'lone black king on d7',
		fen => '8/3k4/8/8/8/8/4K3/8 b - - 0 1',
		moves => [qw(d7e7 d7e6 d7d6 d7c6 d7c7 d7c8 d7d8 d7e8)],
	},
	{
		name => 'lone white king on h1',
		fen => '8/3k4/8/8/8/8/8/7K w - - 0 1',
		moves => [qw(h1g1 h1g2 h1h2)],
	},
	{
		name => 'lone black king on a8',
		fen => 'k7/8/8/8/8/8/3K4/8 b - - 0 1',
		moves => [qw(a8b8 a8b7 a8a7)],
	},
	{
		name => 'lone white king on 1st rank',
		fen => '3k4/8/8/8/8/8/8/4K3 w - - 0 1',
		moves => [qw(e1d1 e1d2 e1e2 e1f2 e1f1)],
	},
	{
		name => 'lone black king on 8th rank',
		fen => '3k4/8/8/8/8/8/8/4K3 b - - 0 1',
		moves => [qw(d8e8 d8e7 d8d7 d8c7 d8c8)],
	},
	{
		name => 'lone white king on h file',
		fen => '8/8/k7/8/8/7K/8/8 w - - 0 1',
		moves => [qw(h3h2 h3g2 h3g3 h3g4 h3h4)],
	},
	{
		name => 'lone black king on a file',
		fen => '8/8/k7/8/8/7K/8/8 b - - 0 1',
		moves => [qw(a6b6 a6b5 a6a5 a6a7 a6b7)],
	},
	# Knight moves.
	{
		name => 'knight on d5',
		fen => '6nK/6PP/8/3N4/8/8/8/k7 w - - 0 1',
		moves => [qw(h8g8 d5e7 d5f6 d5f4 d5e3 d5c3 d5b4 d5b6 d5c7)],
	},
	{
		name => 'knight on g4',
		fen => '6nK/6PP/8/8/6N1/8/8/k7 w - - 0 1',
		moves => [qw(h8g8 g4h6 g4h2 g4f2 g4e3 g4e5 g4f6)],
	},
	{
		name => 'knight on h4',
		fen => '6nK/6PP/8/8/7N/8/8/k7 w - - 0 1',
		moves => [qw(h8g8 h4g2 h4f3 h4f5 h4g6)],
	},
	{
		name => 'knight on d2',
		fen => '6nK/6PP/8/8/8/8/3N4/k7 w - - 0 1',
		moves => [qw(h8g8 d2f1 d2b1 d2b3 d2c4 d2e4 d2f3)],
	},
	{
		name => 'knight on d1',
		fen => '6nK/6PP/8/8/8/8/8/k2N4 w - - 0 1',
		moves => [qw(h8g8 d1b2 d1c3 d1e3 d1f2)],
	},
	{
		name => 'knight on b5',
		fen => '6nK/6PP/8/1N6/8/8/8/k7 w - - 0 1',
		moves => [qw(h8g8 b5c7 b5d6 b5d4 b5c3 b5a3 b5a7)],
	},
	{
		name => 'knight on a5',
		fen => '6nK/6PP/8/N7/8/8/8/k7 w - - 0 1',
		moves => [qw(h8g8 a5b7 a5c6 a5c4 a5b3)],
	},
	{
		name => 'knight on d7',
		fen => '6nK/3N2PP/8/8/8/8/8/k7 w - - 0 1',
		moves => [qw(h8g8 d7f8 d7f6 d7e5 d7c5 d7b6 d7b8)],
	},
	{
		name => 'knight on d8',
		fen => '3N2nK/6PP/8/8/8/8/8/k7 w - - 0 1',
		moves => [qw(h8g8 d8f7 d8e6 d8c6 d8b7)],
	},
	{
		name => 'knight on f6 with capture on g8',
		fen => '6nK/6PP/5N2/8/8/8/8/k7 w - - 0 1',
		moves => [qw(h8g8 f6g8 f6h5 f6g4 f6e4 f6d5 f6d7 f6e8)],
	},
	{
		name => 'knight on h1',
		fen => '6nK/6PP/8/8/8/8/8/k6N w - - 0 1',
		moves => [qw(h8g8 h1f2 h1g3)],
	},
	{
		name => 'knight on a1',
		fen => '6nK/6PP/8/8/8/8/8/N6k w - - 0 1',
		moves => [qw(h8g8 a1b3 a1c2)],
	},
	{
		name => 'knight on a8',
		fen => 'N5nK/6PP/8/8/8/8/8/7k w - - 0 1',
		moves => [qw(h8g8 a8c7 a8b6)],
	},
	{
		name => 'knight on h8',
		fen => 'Kn5N/PP6/8/8/8/8/8/7k w - - 0 1',
		moves => [qw(a8b8 h8g6 h8f7)],
	},
	# Bishop moves.
	{
		name => 'bishop on e4',
		fen => '4b1nK/6PP/8/6p1/4B1P1/8/2n1b3/k7 w - - 0 1',
		moves => [qw(h8g8 e4f5 e4g6 e4f3 e4g2 e4h1 e4d3 e4c2 e4d5 e4c6
				e4b7 e4a8)],
	},
	# Rook moves.
	{
		name => 'bishop on e4',
		fen => '4b1nK/6PP/8/6p1/4R1P1/8/2n1b3/k7 w - - 0 1',
		moves => [qw(h8g8 e4f4 e4e3 e4e2 e4d4 e4c4 e4b4 e4a4 e4e5 e4e6 e4e7
				e4e8)],
	},
	# Queen moves.
	{
		name => 'queen on e4',
		fen => '4b1nK/6PP/8/6p1/4Q1P1/8/2n1b3/k7 w - - 0 1',
		moves => [qw(h8g8 e4f4 e4e3 e4e2 e4d4 e4c4 e4b4 e4a4 e4e5 e4e6 e4e7
				e4e8 e4f5 e4g6 e4f3 e4g2 e4h1 e4d3 e4c2 e4d5 e4c6
				e4b7 e4a8)],
	},
	# Pawn moves.
	{
		name => 'white passed pawn on e4',
		fen => '6nK/6Pn/8/8/4P3/8/8/k7 w - - 0 1',
		moves => [qw(h8g8 h8h7 e4e5)],
	},
	{
		name => 'black passed pawn on e5',
		fen => 'K7/8/8/4p3/8/8/6pN/6Nk b - - 0 1',
		moves => [qw(h1g1 h1h2 e5e4)],
	},
	{
		name => 'white pawn double-steps',
		fen => '6nK/6Pn/8/8/3p4/2p5/2PPP3/k7 w - - 0 1',
		moves => [qw(h8g8 h8h7 d2c3 d2d3 e2e3 e2e4)],
	},
	{
		name => 'black pawn double-steps',
		fen => 'K7/2ppp3/2P5/3P4/8/8/6pN/6Nk b - - 0 1',
		moves => [qw(h1g1 h1h2 d7c6 d7d6 e7e6 e7e5)],
	},
	{
		name => 'white pawn captures',
		fen => '6nK/6Pn/8/pp4pp/Pbp2pbP/1Pprp1P1/3P4/k7 w - - 0 1',
		moves => [qw(h8g8 h8h7 a4b5 b3c4 d2c3 d2e3 g3f4 h4g5)],
	},
	{
		name => 'black pawn captures',
		fen => 'K7/3p4/1pPRP1p1/pBP2PBp/PP4PP/8/6pN/6Nk b - - 0 1',
		moves => [qw(h1g1 h1h2 a5b4 b6c5 d7c6 d7e6 g6f5 h5g4)],
	},
	{
		name => 'white ep captures',
		fen => '6nK/6Pn/8/1PpP4/8/8/8/k7 w - c6 0 1',
		moves => [qw(h8g8 h8h7 b5b6 b5c6 d5c6 d5d6)],
	},
	{
		name => 'black ep captures',
		fen => 'K7/8/8/8/1pPp4/8/6pN/6Nk b - c3 0 1',
		moves => [qw(h1g1 h1h2 b4b3 b4c3 d4c3 d4d3)],
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Position->new($test->{fen});
	my @moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalMoves;
	my @expect = sort @{$test->{moves}};
	is(scalar(@moves), scalar(@expect), "number of moves $test->{name}");
	is_deeply \@moves, \@expect, $test->{name};
	if (@moves != @expect) {
		diag Dumper [sort @moves];
	}
}

done_testing;
