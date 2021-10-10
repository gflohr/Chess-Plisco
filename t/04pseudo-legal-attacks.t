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
use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

my ($pos, @moves, @expect);

my @tests = (
	{
		name => 'promotion bug',
		fen => 'r5k1/2Q3p1/p1n1q1p1/3p2P1/P7/7P/3p2PK/3q4 b - - 0 34',
		moves => [qw(e6h3 d1a4)],
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	foreach my $movestr (@{$test->{premoves} || []}) {
		my $move = $pos->parseMove($movestr);
		ok $move, "$test->{name}: parse $movestr";
		ok $pos->doMove($move), "$test->{name}: premove $movestr should be legal";
	}
	my @moves = sort map { cp_move_coordinate_notation($_) } $pos->pseudoLegalAttacks;
	my @expect = sort @{$test->{moves}};
	is(scalar(@moves), scalar(@expect), "number of moves $test->{name}");
	is_deeply \@moves, \@expect, $test->{name};
	if (@moves != @expect) {
		diag Dumper [sort @moves];
	}

	foreach my $move ($pos->pseudoLegalMoves) {
		# Check the correct piece.
		my $from_mask = 1 << (cp_move_from $move);
		my $got_piece = cp_move_piece $move;
		my $piece;
		if ($from_mask & cp_pos_pawns($pos)) {
			$piece = CP_PAWN;
		} elsif ($from_mask & cp_pos_knights($pos)) {
			$piece = CP_KNIGHT;
		} elsif ($from_mask & cp_pos_bishops($pos)) {
			$piece = CP_BISHOP;
		} elsif ($from_mask & cp_pos_rooks($pos)) {
			$piece = CP_ROOK;
		} elsif ($from_mask & cp_pos_queens($pos)) {
			$piece = CP_QUEEN;
		} elsif ($from_mask & cp_pos_kings($pos)) {
			$piece = CP_KING;
		} else {
			die "Move $move piece is $got_piece, but no match with bitboards\n";
		}

		my $movestr = cp_move_coordinate_notation $move;
		is(cp_move_piece($move), $piece, "correct piece for $movestr");
	}
}

done_testing;
