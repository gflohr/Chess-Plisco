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
		name => 'legal moves bug 1',
		fen => '1B3b1R/2q4b/2nn1Kp1/3p2p1/r7/k6r/p1p1p1p1/2RN1B1N b - - 0 1',
		moves => [qw(
			a2a1q a2a1r a2a1b a2a1n c2d1q c2d1r
			c2d1b c2d1n e2e1q e2e1r e2e1b e2e1n
			e2f1q e2f1r e2f1b e2f1n e2d1q e2d1r
			e2d1b e2d1n g2g1q g2g1r g2g1b g2g1n
			g2h1q g2h1r g2h1b g2h1n g2f1q g2f1r
			g2f1b g2f1n a3b4 a3b3 h3h4 h3h5
			h3h6 h3h2 h3h1 h3g3 h3f3 h3e3
			h3d3 h3c3 h3b3 a4b4 a4c4 a4d4
			a4e4 a4f4 a4g4 a4h4 a4a5 a4a6
			a4a7 a4a8 d5d4 g5g4 c6b8 c6d8
			c6a7 c6e7 c6a5 c6e5 c6b4 c6d4
			d6c8 d6e8 d6b7 d6f7 d6b5 d6f5
			d6c4 d6e4 c7d7 c7e7 c7f7 c7g7
			c7c8 c7b7 c7a7 c7b8 c7d8 c7b6
			c7a5 h7g8 f8g7 f8h6 f8e7
		)],
	},
	{
		name => 'allow king to evade check',
		fen => 'r3k2r/p1ppqpb1/1n2pnp1/3PN3/1p2P3/2N2Q1p/PPPBbPPP/R4K1R w KQkq - 0 1',
		moves => [qw(c3e2 f1e1 f1g1 f3e2 f1e2)],
	}
);

foreach my $test (@tests) {
	my $pos = Chess::Position->new($test->{fen});
	foreach my $movestr (@{$test->{premoves} || []}) {
		my $move = Chess::Position::Move->new($movestr, $pos)->toInteger;
		ok $pos->doMove($move), "$test->{name}: premove $movestr should be legal";
	}

	my @moves = sort map { cp_move_coordinate_notation($_) } $pos->legalMoves;
	my @expect = sort @{$test->{moves}};
	is(scalar(@moves), scalar(@expect), "number of moves $test->{name}");
	is_deeply \@moves, \@expect, $test->{name};
	if (@moves != @expect) {
		diag Dumper [sort @moves];
	}

	foreach my $move ($pos->pseudoLegalMoves) {
		# Check the correct attacker.
		my $from_mask = 1 << (cp_move_from $move);
		my $got_attacker = cp_move_attacker $move;
		my $attacker;
		if ($from_mask & cp_pos_pawns($pos)) {
			$attacker = CP_PAWN;
		} elsif ($from_mask & cp_pos_knights($pos)) {
			$attacker = CP_KNIGHT;
		} elsif ($from_mask & cp_pos_bishops($pos)) {
			if ($from_mask & cp_pos_rooks($pos)) {
				# Did it move like a bishop or like a queen?
				my ($from, $to) = (cp_move_from($move), cp_move_to($move));
				my ($from_file, $from_rank) = $pos->shiftToCoordinates($from);
				my ($to_file, $to_rank) = $pos->shiftToCoordinates($to);
				if (($from_file != $to_file) && ($from_rank != $to_rank)) {
					$attacker = CP_BISHOP;
				} else {
					$attacker = CP_ROOK;
				}
			} else {
				$attacker = CP_BISHOP;
			}
		} elsif ($from_mask & cp_pos_rooks($pos)) {
			$attacker = CP_ROOK;
		} elsif ($from_mask & cp_pos_kings($pos)) {
			$attacker = CP_KING;
		} else {
			die "Move $move attacker is $got_attacker, but no match with bitboards\n";
		}

		my $movestr = cp_move_coordinate_notation $move;
		is(cp_move_attacker($move), $attacker, "correct attacker for $movestr");
	}
}

done_testing;
