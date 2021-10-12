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

use constant CP_POS_GAME_PHASE => 14;
use constant CP_POS_OPENING_SCORE => 15;
use constant CP_POS_ENDGAME_SCORE => 16;

# Piece-square tables.  They are always from black's perspective.
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

use constant PAWN_PHASE => 0;
use constant KNIGHT_PHASE => 1;
use constant BISHOP_PHASE => 1;
use constant ROOK_PHASE => 2;
use constant QUEEN_PHASE => 4;
use constant TOTAL_PHASE => PAWN_PHASE * 16
	+ KNIGHT_PHASE * 4 + BISHOP_PHASE * 4
	+ ROOK_PHASE * 4 + QUEEN_PHASE * 2;

# For all combinations of victim and promotion piece, calculate the change in
# game phase.  These values are positive and meant to be added to the phase;
my @move_phase_deltas = (0) x 369;
my @piece_phases = (
	0,
	PAWN_PHASE,
	KNIGHT_PHASE,
	BISHOP_PHASE,
	ROOK_PHASE,
	QUEEN_PHASE,
);
foreach my $victim (CP_NO_PIECE, CP_PAWN .. CP_QUEEN) {
	foreach my $promote (CP_NO_PIECE, CP_KNIGHT .. CP_QUEEN) {
		next if $promote && $victim == CP_PAWN;
		next if !$victim && !$promote;
		my $delta = $piece_phases[$victim];
		if ($promote) {
			$delta += (Chess::Plisco::Engine::Position::PAWN_PHASE
				- $piece_phases[$promote]);
		}
		$move_phase_deltas[($victim << 3) | $promote] = $delta;
	}
}

# Lookup tables for the resulting opening and endgame scores for each
# possible move.
my @opening_deltas;
my @endgame_deltas;

# __BEGIN_MACROS__

my @opening_tables = (
	[],
	\@pawn_square_table,
	\@knight_square_table,
	\@bishop_square_table,
	\@rook_square_table,
	\@queen_square_table,
	\@king_middle_game_square_table,
);
my @endgame_tables = (
	[],
	\@pawn_square_table,
	\@knight_square_table,
	\@bishop_square_table,
	\@rook_square_table,
	\@queen_square_table,
	\@king_end_game_square_table,
);
foreach my $move (Chess::Plisco->moveNumbers) {
	my $is_ep;
	my $color = 1 & ($move >> 21);
	my $captured = 0x7 & ($move >> 18);
	if ($captured == CP_KING) {
		$captured = CP_PAWN;
		$is_ep = 1;
	}
	my ($to, $from, $promote, $piece) = (
		Chess::Plisco->moveTo($move),
		Chess::Plisco->moveFrom($move),
		Chess::Plisco->movePromote($move),
		Chess::Plisco->movePiece($move),
	);

	if (CP_WHITE == $color) {
		$from ^= 56;
		$to ^= 56;
	}

	my $opening_delta = $opening_tables[$piece]->[$to]
		- $opening_tables[$piece]->[$from];
	my $endgame_delta = $opening_tables[$piece]->[$to]
		- $opening_tables[$piece]->[$from];
	if ($is_ep) {
		$opening_delta -= $opening_tables[CP_PAWN]->[$to + 8];
		$endgame_delta -= $endgame_tables[CP_PAWN]->[$to + 8];
	} elsif ($captured) {
		# The captured piece must be viewed from the other side.
		$opening_delta += $opening_tables[$captured]->[$to ^ 56];
		$endgame_delta += $opening_tables[$captured]->[$to ^ 56];
	}

	if ($promote) {
		$opening_delta += $opening_tables[$promote]->[$to]
			- $pawn_square_table[$to];
		$endgame_delta += $endgame_tables[$promote]->[$to]
			- $pawn_square_table[$to];
	}

	# Handle castlings. Again, everything is from black's perspective.
	if (CP_KING == $piece && CP_E8 == $from) {
		if (CP_C8 == $to) {
			$opening_delta += $opening_tables[CP_ROOK]->[CP_D8]
				- $opening_tables[CP_ROOK]->[CP_A8];
			$endgame_delta += $endgame_tables[CP_ROOK]->[CP_D8]
				- $opening_tables[CP_ROOK]->[CP_A8];
		} elsif (CP_G8 == $to) {
			$opening_delta += $opening_tables[CP_ROOK]->[CP_F8]
				- $opening_tables[CP_ROOK]->[CP_H8];
			$endgame_delta += $endgame_tables[CP_ROOK]->[CP_F8]
				- $endgame_tables[CP_ROOK]->[CP_H8];
		}
	}

	$opening_deltas[$move] = $color ? -$opening_delta : $opening_delta;
	$endgame_deltas[$move] = $color ? -$endgame_delta : $endgame_delta;
}

sub new {
	my ($class, @args) = @_;

	my $self = $class->SUPER::new(@args);

	$self->[CP_POS_GAME_PHASE] = TOTAL_PHASE;

	my $score = 0;
	my $white_pieces = $self->[CP_POS_WHITE_PIECES];
	my $black_pieces = $self->[CP_POS_BLACK_PIECES];
	my $pawns = $self->[CP_POS_PAWNS];
	my $knights = $self->[CP_POS_KNIGHTS];
	my $bishops = $self->[CP_POS_BISHOPS];
	my $rooks = $self->[CP_POS_ROOKS];
	my $queens = $self->[CP_POS_QUEENS];
	my $kings = $self->[CP_POS_KINGS];

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
	my $phase = 0;

	while ($white_pawns) {
		my $shift = cp_bitboard_count_trailing_zbits $white_pawns;
		$score += $pawn_square_table[$shift ^ 56];
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
		$score += $knight_square_table[$shift ^ 56];
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
		$score += $bishop_square_table[$shift ^ 56];
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
		$score += $rook_square_table[$shift ^ 56];
		$white_rooks = cp_bitboard_clear_least_set $white_rooks;
		$phase -= ROOK_PHASE;
	}

	while ($black_rooks) {
		my $shift = cp_bitboard_count_trailing_zbits $black_rooks;
		$score -= $rook_square_table[$shift];
		$black_rooks = cp_bitboard_clear_least_set $black_rooks;
		$phase -= ROOK_PHASE;
	}

	while ($white_queens) {
		my $shift = cp_bitboard_count_trailing_zbits $white_queens;
		$score += $queen_square_table[$shift ^ 56];
		$white_queens = cp_bitboard_clear_least_set $white_queens;
		$phase -= ROOK_PHASE;
	}

	while ($black_queens) {
		my $shift = cp_bitboard_count_trailing_zbits $black_queens;
		$score -= $queen_square_table[$shift];
		$black_queens = cp_bitboard_clear_least_set $black_queens;
		$phase -= ROOK_PHASE;
	}

	$phase = 0 if $phase < 0;
	$phase = ($phase * 256 + (TOTAL_PHASE / 2)) / TOTAL_PHASE;
	$self->[CP_POS_GAME_PHASE] = $phase;

	my $white_king_shift = (cp_bitboard_count_trailing_zbits $white_kings) ^ 56;
	my $black_king_shift = cp_bitboard_count_trailing_zbits $black_kings;
	$self->[CP_POS_OPENING_SCORE] = $score
		+ $king_middle_game_square_table[$white_king_shift]
		- $king_middle_game_square_table[$black_king_shift];
	$self->[CP_POS_ENDGAME_SCORE] = $score
		+ $king_end_game_square_table[$white_king_shift]
		- $king_end_game_square_table[$black_king_shift];

	return $self;
}

sub doMove {
	my ($self, $move) = @_;

	my $state = $self->SUPER::doMove($move) or return;
	($move) = @$state;
	$self->[CP_POS_GAME_PHASE] += $move_phase_deltas[
		(cp_move_captured($move) << 3) | cp_move_promote($move)
	];
	my $score_index = ($move & 0x1fffff) | (!(cp_pos_to_move($self)) << 21);
	$self->[CP_POS_OPENING_SCORE] += $opening_deltas[$score_index];
	$self->[CP_POS_ENDGAME_SCORE] += $endgame_deltas[$score_index];

	return $state;
}

sub evaluate {
	my ($self) = @_;

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
			return Chess::Plisco::Engine::Tree::DRAW();
		}
	}
	my $phase = $self->[CP_POS_GAME_PHASE];

	$phase = 0 if $phase < 0;
	$phase = ($phase * 256 + (TOTAL_PHASE / 2)) / TOTAL_PHASE;

	my $score = (($self->[CP_POS_OPENING_SCORE] * (256 - $phase))
			+ ($self->[CP_POS_ENDGAME_SCORE] * $phase)) / 256
		+ $material;

	return (cp_pos_to_move($self)) ? -$score : $score;
}

# __END_MACROS__

sub openingDelta {
	my ($self, $index) = @_;

	return $opening_deltas[$index];
}

sub endgameDelta {
	my ($self, $index) = @_;

	return $endgame_deltas[$index];
}

1;
