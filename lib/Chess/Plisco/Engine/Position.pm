#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine::Position;

use strict;
use integer;

use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;
use Chess::Plisco::Engine::Tree;

use base qw(Chess::Plisco);

# Piece-square tables.  There are always from black's perspective.
my @pawn_square_table = (
	 0,  0,  0,  0,  0,  0,  0,  0,
	50, 50, 50, 50, 50, 50, 50, 50,
	10, 10, 20, 30, 30, 20, 10, 10,
	 5,  5, 10, 25, 25, 10,  5,  5,
	 0,  0,  0, 20, 20,  0,  0,  0,
	 5, -5,-10,  0,  0,-10, -5,  5,
	 5, 10, 10,-20,-20, 10, 10,  5,
	 0,  0,  0,  0,  0,  0,  0,  0,
);

my @knight_square_table = (
	-50,-40,-30,-30,-30,-30,-40,-50,
	-40,-20,  0,  0,  0,  0,-20,-40,
	-30,  0, 10, 15, 15, 10,  0,-30,
	-30,  5, 15, 20, 20, 15,  5,-30,
	-30,  0, 15, 20, 20, 15,  0,-30,
	-30,  5, 10, 15, 15, 10,  5,-30,
	-40,-20,  0,  5,  5,  0,-20,-40,
	-50,-40,-30,-30,-30,-30,-40,-50,
);

my @bishop_square_table = (
	-20,-10,-10,-10,-10,-10,-10,-20,
	-10,  0,  0,  0,  0,  0,  0,-10,
	-10,  0,  5, 10, 10,  5,  0,-10,
	-10,  5,  5, 10, 10,  5,  5,-10,
	-10,  0, 10, 10, 10, 10,  0,-10,
	-10, 10, 10, 10, 10, 10, 10,-10,
	-10,  5,  0,  0,  0,  0,  5,-10,
	-20,-10,-10,-10,-10,-10,-10,-20,
);

my @rook_square_table = (
	 0,  0,  0,  0,  0,  0,  0,  0,
	 5, 10, 10, 10, 10, 10, 10,  5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	 0,  0,  0,  5,  5,  0,  0,  0,
);

my @queen_square_table = (
	-20,-10,-10, -5, -5,-10,-10,-20,
	-10,  0,  0,  0,  0,  0,  0,-10,
	-10,  0,  5,  5,  5,  5,  0,-10,
	 -5,  0,  5,  5,  5,  5,  0, -5,
	  0,  0,  5,  5,  5,  5,  0, -5,
	-10,  5,  5,  5,  5,  5,  0,-10,
	-10,  0,  5,  0,  0,  0,  0,-10,
	-20,-10,-10, -5, -5,-10,-10,-20,
);

my @king_middle_game_square_table = (
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-20,-30,-30,-40,-40,-30,-30,-20,
	-10,-20,-20,-20,-20,-20,-20,-10,
	 20, 20,  0,  0,  0,  0, 20, 20,
	 20, 30, 10,  0,  0, 10, 30, 20,
);

my @king_end_game_square_table = (
	-50,-40,-30,-20,-20,-30,-40,-50,
	-30,-20,-10,  0,  0,-10,-20,-30,
	-30,-10, 20, 30, 30, 20,-10,-30,
	-30,-10, 30, 40, 40, 30,-10,-30,
	-30,-10, 30, 40, 40, 30,-10,-30,
	-30,-10, 20, 30, 30, 20,-10,-30,
	-30,-30,  0,  0,  0,  0,-30,-30,
	-50,-30,-30,-30,-30,-30,-30,-50,
);

# __BEGIN_MACROS__

use constant PAWN_PHASE => 0;
use constant KNIGHT_PHASE => 1;
use constant BISHOP_PHASE => 1;
use constant ROOK_PHASE => 2;
use constant QUEEN_PHASE => 4;
use constant TOTAL_PHASE => PAWN_PHASE * 16
	+ KNIGHT_PHASE * 4 + BISHOP_PHASE * 4
	+ ROOK_PHASE * 4 + QUEEN_PHASE * 2;

sub evaluate {
	my ($self) = @_;

	my $score = 0;
	my $material = cp_pos_material $self;
	my $white_pieces = $self->[CP_POS_WHITE_PIECES];
	my $black_pieces = $self->[CP_POS_BLACK_PIECES];
	my $pawns = $self->[CP_POS_PAWNS];
	my $knights = $self->[CP_POS_KNIGHTS];
	my $bishops = $self->[CP_POS_BISHOPS];
	my $rooks = $self->[CP_POS_ROOKS];
	my $queens = $self->[CP_POS_QUEENS];
	my $kings = $self->[CP_POS_KINGS];

	# We simply assume that a position without pawns is in general a draw.
	# If one side is a minor piece ahead, it is considered a draw, when there
	# are no rooks or queens on the board.  Important exception is KBB vs KN.
	# But in that case the material delta is B + B - N which is greater
	# than B.  On the other hand KBB vs KB is a draw and the material balance
	# in that case is exactly one bishop.
	# These simple formulas do not take into account that there may be more
	# than two knights or bishops for one side on the board but in the
	# exceptional case that this happens, the result would be close enough
	# anyway.
	if (!$pawns) {
		my $delta = cp_abs($material);
		if ($delta < CP_PAWN_VALUE
		    || (!$rooks && !$queens
		        && (($delta <= CP_BISHOP_VALUE)
		            || ($delta == 2 * CP_KNIGHT_VALUE)
			        || ($delta == CP_KNIGHT_VALUE + CP_BISHOP_VALUE)))) {
			return Chess::Plisco::Engine::Tree::DRAW;
		}
	}

	my $white_pawns = $white_pieces & $pawns;
	my $black_pawns = $black_pieces & $pawns;
	my $white_knights = $white_pieces & $knights;
	my $black_knights = $black_pieces & $knights;
	my $white_bishops = $white_pieces & $bishops;
	my $black_bishops = $black_pieces & $bishops;
	my $white_rooks = $white_pieces & $rooks;
	my $black_rooks = $black_pieces & $rooks;
	my $white_queens = $white_pieces & $queens;
	my $black_queens = $black_pieces & $queens;
	my $white_kings = $white_pieces & $kings;
	my $black_kings = $black_pieces & $kings;

	my $phase = TOTAL_PHASE;

	while ($white_pawns) {
		my $shift = cp_bitboard_count_trailing_zbits $white_pawns;
		$score += $pawn_square_table[63 - $shift];
		$white_pawns = cp_bitboard_clear_least_set $white_pawns;
		$phase -= PAWN_PHASE;
	}

	while ($black_pawns) {
		my $shift = cp_bitboard_count_trailing_zbits $black_pawns;
		$score -= $pawn_square_table[$shift];
		$black_pawns = cp_bitboard_clear_least_set $black_pawns;
		$phase -= PAWN_PHASE;
	}

	while ($white_knights) {
		my $shift = cp_bitboard_count_trailing_zbits $white_knights;
		$score += $knight_square_table[63 - $shift];
		$white_knights = cp_bitboard_clear_least_set $white_knights;
		$phase -= KNIGHT_PHASE;
	}

	while ($black_knights) {
		my $shift = cp_bitboard_count_trailing_zbits $black_knights;
		$score -= $knight_square_table[$shift];
		$black_knights = cp_bitboard_clear_least_set $black_knights;
		$phase -= KNIGHT_PHASE;
	}

	while ($white_bishops) {
		my $shift = cp_bitboard_count_trailing_zbits $white_bishops;
		$score += $bishop_square_table[63 - $shift];
		$white_bishops = cp_bitboard_clear_least_set $white_bishops;
		$phase -= BISHOP_PHASE;
	}

	while ($black_bishops) {
		my $shift = cp_bitboard_count_trailing_zbits $black_bishops;
		$score -= $bishop_square_table[$shift];
		$black_bishops = cp_bitboard_clear_least_set $black_bishops;
		$phase -= BISHOP_PHASE;
	}

	while ($white_rooks) {
		my $shift = cp_bitboard_count_trailing_zbits $white_rooks;
		$score += $rook_square_table[63 - $shift];
		$white_rooks = cp_bitboard_clear_least_set $white_rooks;
		$phase -= ROOK_PHASE;
	}

	while ($black_rooks) {
		my $shift = cp_bitboard_count_trailing_zbits $black_rooks;
		$score -= $rook_square_table[$shift];
		$black_rooks = cp_bitboard_clear_least_set $black_rooks;
		$phase -= ROOK_PHASE;
	}

	# Count them only once.
	$phase -= QUEEN_PHASE if $white_queens;
	while ($white_queens) {
		my $shift = cp_bitboard_count_trailing_zbits $white_queens;
		$score += $queen_square_table[63 - $shift];
		$white_queens = cp_bitboard_clear_least_set $white_queens;
	}

	# Count them only once.
	$phase -= QUEEN_PHASE if $black_queens;
	while ($black_queens) {
		my $shift = cp_bitboard_count_trailing_zbits $black_queens;
		$score -= $queen_square_table[$shift];
		$black_queens = cp_bitboard_clear_least_set $black_queens;
	}

	$phase = 0 if $phase < 0;
	$phase = ($phase * 256 + (TOTAL_PHASE / 2)) / TOTAL_PHASE;

	my $white_king_shift = cp_bitboard_count_trailing_zbits $white_kings;
	my $black_king_shift = cp_bitboard_count_trailing_zbits $black_kings;
	my $opening_score = $score + $king_middle_game_square_table[63 - $white_king_shift]
		- $king_middle_game_square_table[$black_king_shift];
	my $endgame_score = $score + $king_end_game_square_table[63 - $white_king_shift]
		- $king_end_game_square_table[$black_king_shift];
	$score = (($opening_score * (256 - $phase))
			+ ($endgame_score * $phase)) / 256
		+ $material;

	return (cp_pos_to_move($self)) ? -$score : $score;
}

# __END_MACROS__

1;
