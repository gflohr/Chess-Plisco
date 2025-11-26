#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Portions of this code have been ported from C code that has the following
# copyright notice:

# Copyright (C) 2007 Pradyumna Kannan.
#
# This code is provided 'as-is', without any express or implied warranty.
# In no event will the authors be held liable for any damages arising from
# the use of this code. Permission is granted to anyone to use this
# code for any purpose, including commercial applications, and to alter
# it and redistribute it freely, subject to the following restrictions:
# 
# 1. The origin of this code must not be misrepresented; you must not
# claim that you wrote the original code. If you use this code in a
# product, an acknowledgment in the product documentation would be
# appreciated but is not required.
# 
# 2. Altered source versions must be plainly marked as such, and must not be
# misrepresented as being the original code.
# 
# 3. This notice may not be removed or altered from any source distribution.

# Make Dist::Zilla happy.
# ABSTRACT: Representation of a chess position with move generator, legality checker etc.

# Welcome to the world of spaghetti code!  It is deliberately ugly because
# trying to avoid function/method call overhead is one of the major goals.
# In the future it may make sense to try to make the code more readable by
# more extensive use of Chess::Plisco::Macro.

package Chess::Plisco;

use strict;
use integer;

use Locale::TextDomain qw('Chess-Plisco');
use Scalar::Util qw(reftype);
use Config;

use Chess::Plisco::Macro;

use base qw(Exporter);

# Colors.
use constant CP_WHITE => 0;
use constant CP_BLACK => 1;

# Piece constants.
use constant CP_NO_PIECE => 0;
use constant CP_PAWN => 1;
use constant CP_KNIGHT => 2;
use constant CP_BISHOP => 3;
use constant CP_ROOK => 4;
use constant CP_QUEEN => 5;
use constant CP_KING => 6;
use constant CP_PAWN_VALUE => 100;
use constant CP_KNIGHT_VALUE => 320;
use constant CP_BISHOP_VALUE => 330;
use constant CP_ROOK_VALUE => 500;
use constant CP_QUEEN_VALUE => 900;

# Accessor indices.  The layout is selected in such a way that piece types
# can be used directly as indices in order to get the corresponding bitboard,
# and getting the pieces for the side to move and the side not to move can
# be simplified by just adding the color or the negated color to the index
# of the white pieces.  This must not change in future versions!
use constant CP_POS_HALFMOVES => 0;
use constant CP_POS_PAWNS => CP_PAWN;
use constant CP_POS_KNIGHTS => CP_KNIGHT;
use constant CP_POS_BISHOPS => CP_BISHOP;
use constant CP_POS_ROOKS => CP_ROOK;
use constant CP_POS_QUEENS => CP_QUEEN;
use constant CP_POS_KINGS => CP_KING;
use constant CP_POS_WHITE_PIECES => 7;
use constant CP_POS_BLACK_PIECES => 8;
# 5 reserved slots.
# FIXME! Define CP_POS_USR1, ...
use constant CP_POS_INFO => 14;
use constant CP_POS_LAST_FIELD => 14;

# How to evade a check?
use constant CP_EVASION_ALL => 0;
use constant CP_EVASION_CAPTURE => 1;
use constant CP_EVASION_KING_MOVE => 2;

# Board masks and shifts.
# Squares.
use constant CP_A1 => 0;
use constant CP_B1 => 1;
use constant CP_C1 => 2;
use constant CP_D1 => 3;
use constant CP_E1 => 4;
use constant CP_F1 => 5;
use constant CP_G1 => 6;
use constant CP_H1 => 7;
use constant CP_A2 => 8;
use constant CP_B2 => 9;
use constant CP_C2 => 10;
use constant CP_D2 => 11;
use constant CP_E2 => 12;
use constant CP_F2 => 13;
use constant CP_G2 => 14;
use constant CP_H2 => 15;
use constant CP_A3 => 16;
use constant CP_B3 => 17;
use constant CP_C3 => 18;
use constant CP_D3 => 19;
use constant CP_E3 => 20;
use constant CP_F3 => 21;
use constant CP_G3 => 22;
use constant CP_H3 => 23;
use constant CP_A4 => 24;
use constant CP_B4 => 25;
use constant CP_C4 => 26;
use constant CP_D4 => 27;
use constant CP_E4 => 28;
use constant CP_F4 => 29;
use constant CP_G4 => 30;
use constant CP_H4 => 31;
use constant CP_A5 => 32;
use constant CP_B5 => 33;
use constant CP_C5 => 34;
use constant CP_D5 => 35;
use constant CP_E5 => 36;
use constant CP_F5 => 37;
use constant CP_G5 => 38;
use constant CP_H5 => 39;
use constant CP_A6 => 40;
use constant CP_B6 => 41;
use constant CP_C6 => 42;
use constant CP_D6 => 43;
use constant CP_E6 => 44;
use constant CP_F6 => 45;
use constant CP_G6 => 46;
use constant CP_H6 => 47;
use constant CP_A7 => 48;
use constant CP_B7 => 49;
use constant CP_C7 => 50;
use constant CP_D7 => 51;
use constant CP_E7 => 52;
use constant CP_F7 => 53;
use constant CP_G7 => 54;
use constant CP_H7 => 55;
use constant CP_A8 => 56;
use constant CP_B8 => 57;
use constant CP_C8 => 58;
use constant CP_D8 => 59;
use constant CP_E8 => 60;
use constant CP_F8 => 61;
use constant CP_G8 => 62;
use constant CP_H8 => 63;

# Files.
use constant CP_A_MASK => 0x0101010101010101;
use constant CP_B_MASK => 0x0202020202020202;
use constant CP_C_MASK => 0x0404040404040404;
use constant CP_D_MASK => 0x0808080808080808;
use constant CP_E_MASK => 0x1010101010101010;
use constant CP_F_MASK => 0x2020202020202020;
use constant CP_G_MASK => 0x4040404040404040;
use constant CP_H_MASK => 0x8080808080808080;

# Ranks.
use constant CP_1_MASK => 0x00000000000000ff;
use constant CP_2_MASK => 0x000000000000ff00;
use constant CP_3_MASK => 0x0000000000ff0000;
use constant CP_4_MASK => 0x00000000ff000000;
use constant CP_5_MASK => 0x000000ff00000000;
use constant CP_6_MASK => 0x0000ff0000000000;
use constant CP_7_MASK => 0x00ff000000000000;
use constant CP_8_MASK => 0xff00000000000000;

use constant CP_FILE_A => (0);
use constant CP_FILE_B => (1);
use constant CP_FILE_C => (2);
use constant CP_FILE_D => (3);
use constant CP_FILE_E => (4);
use constant CP_FILE_F => (5);
use constant CP_FILE_G => (6);
use constant CP_FILE_H => (7);

use constant CP_RANK_1 => (0);
use constant CP_RANK_2 => (1);
use constant CP_RANK_3 => (2);
use constant CP_RANK_4 => (3);
use constant CP_RANK_5 => (4);
use constant CP_RANK_6 => (5);
use constant CP_RANK_7 => (6);
use constant CP_RANK_8 => (7);

use constant CP_WHITE_MASK => 0x55aa55aa55aa55aa;
use constant CP_BLACK_MASK => 0xaa55aa55aa55aa55;
use constant CP_LIGHT_MASK => 0x55aa55aa55aa55aa;
use constant CP_DARK_MASK => 0xaa55aa55aa55aa55;

use constant CP_PIECE_CHARS => [
	['', 'P', 'N', 'B', 'R', 'Q', 'K'],
	['', 'p', 'n', 'b', 'r', 'q', 'k'],
];

use constant CP_RANDOM_SEED => 0x415C0415C0415C0;
my $cp_random = CP_RANDOM_SEED;

# Game states.
use constant CP_GAME_OVER => 1 << 0;
use constant CP_GAME_WHITE_WINS => 1 << 1;
use constant CP_GAME_BLACK_WINS => 1 << 2;
use constant CP_GAME_STALEMATE => 1 << 3;
use constant CP_GAME_FIFTY_MOVES => 1 << 4;
use constant CP_GAME_INSUFFICIENT_MATERIAL => 1 << 5;

my @pawn_aux_data = (
	# White.
	[
		# Mask for regular moves.
		~(CP_7_MASK | CP_8_MASK),
		# Mask for double moves.
		CP_2_MASK,
		# Promotion mask.
		CP_7_MASK,
		# Single step offset.
		8,
	],
	# Black.
	[
		# Mask for regular moves.
		~(CP_2_MASK | CP_1_MASK),
		# Mask for double moves.
		CP_7_MASK,
		# Promotion mask.
		CP_2_MASK,
		# Single step offset.
		-8,
	],
);

# Map ep squares to the mask of the pawn that gets removed.
my @ep_pawn_masks;

my @castling_aux_data = (
	# White.
	[
		# From shift.
		CP_E1,
		# From mask.
		(CP_E_MASK & CP_1_MASK),
		# King-side crossing square.
		(CP_F_MASK & CP_1_MASK),
		# King-side king's destination square.
		CP_G1,
		# Queen-side crossing mask.
		(CP_D_MASK & CP_1_MASK),
		# Queen-side king's destination square.
		CP_C1,
		# Queen-side rook crossing mask.
		(CP_B_MASK & CP_1_MASK),
	],
	# Black.
	[
		# From shift.
		CP_E8,
		# From mask.
		(CP_E_MASK & CP_8_MASK),
		# King-side crossing mask.
		(CP_F_MASK & CP_8_MASK),
		# King-side king's destination square.
		CP_G8,
		# Queen-side crossing mask.
		(CP_D_MASK & CP_8_MASK),
		# Queen-side king's destination square.
		CP_C8,
		# Queen-side rook crossing mask.
		(CP_B_MASK & CP_8_MASK),
	],
);

# These arrays map a bit shift offset to bitboards that the corresponding
# piece can attack from that square.  They are filled at compile-time at the
# end of this file.
my @king_attack_masks;
my @knight_attack_masks;

# These are for pawn single steps, double steps, and captures,
# first for white then for black.
my @pawn_masks;

# Two-dimensional array for determining common lines (diagonals or files/ranks).
my @common_lines;

# FIXME! Merge them all into one array with one more level so that we save
# array lookups.

# Information for castlings, part 1. Lookup by target square of the king, the
# move mask of the rook and the negative mask for the castling rights.
my @castling_rook_move_masks;

# Information for castlings, part 2. For a1, h1, a8, and h8 remove these
# castling rights.
my @castling_rights_rook_masks;

# Information for castlings, part 3. For the king destination squares c1, g1,
# c8, and g8, where does the rook move? Needed for moveGivesCheck().
my @castling_rook_to_mask;

my @castling_rook_zk_updates;

# Change in material.  Looked up via a combined mask of color to move,
# captured and promotion piece.
my @material_deltas;

# This table is used in the static exchange evaluation in order to
# detect x-ray attacks. It gives a mask of all squares that will
# attack the destination square if a piece moves from the start square to the
# destination square. Example: The "obscured mask" of the bishop move "d3e6"
# is a bitboard with the squares "b1" and "c2" because a queen or bishop on one
# of these two squares will attack "e6", when the bishop moves there.
#
# FIXME! All multi-dimensional lookup tables that are using from and to as
# their index, should changed to just use the lower 12 bits of the move
# instead.  That saves us one array dereferencing.
my @obscured_masks;

my @zk_pieces;
my @zk_castling;
my @zk_ep_files;
my $zk_color;

my @move_numbers;

my @magicmovesbdb;
my @magicmovesrdb;

my @magicmoves_r_magics;
my @magicmoves_r_mask;
my @magicmoves_b_magics;
my @magicmoves_b_mask;

use constant CP_MAGICMOVES_B_MAGICS => \@magicmoves_b_magics;
use constant CP_MAGICMOVES_R_MAGICS => \@magicmoves_r_magics;
use constant CP_MAGICMOVES_B_MASK => \@magicmoves_b_mask;
use constant CP_MAGICMOVES_R_MASK => \@magicmoves_r_mask;
use constant CP_MAGICMOVESBDB => \@magicmovesbdb;
use constant CP_MAGICMOVESRDB => \@magicmovesrdb;

my @piece_values = (0, CP_PAWN_VALUE, CP_KNIGHT_VALUE, CP_BISHOP_VALUE,
	CP_ROOK_VALUE, CP_QUEEN_VALUE);

# Do not remove this line!
# __BEGIN_MACROS__

sub new {
	my ($class, $fen, $relaxed) = @_;

	return $class->newFromFEN($fen, $relaxed) if defined $fen && length $fen;

	my $self = bless [], $class;
	cp_pos_white_pieces($self) = CP_1_MASK | CP_2_MASK;
	cp_pos_black_pieces($self) = CP_8_MASK | CP_7_MASK,
	cp_pos_kings($self) = (CP_1_MASK | CP_8_MASK) & CP_E_MASK;
	cp_pos_queens($self) = (CP_D_MASK & CP_1_MASK)
			| (CP_D_MASK & CP_8_MASK);
	cp_pos_rooks($self) = ((CP_A_MASK | CP_H_MASK) & CP_1_MASK)
			| ((CP_A_MASK | CP_H_MASK) & CP_8_MASK);
	cp_pos_bishops($self) = ((CP_C_MASK | CP_F_MASK) & CP_1_MASK)
			| ((CP_C_MASK | CP_F_MASK) & CP_8_MASK);
	cp_pos_knights($self) = ((CP_B_MASK | CP_G_MASK) & CP_1_MASK)
			| ((CP_B_MASK | CP_G_MASK) & CP_8_MASK);
	cp_pos_pawns($self) = CP_2_MASK | CP_7_MASK;

	cp_pos_halfmoves($self) = 0;

	my $info = 0;
	_cp_pos_info_set_white_king_side_castling_right($info, 1);
	_cp_pos_info_set_white_queen_side_castling_right($info, 1);
	_cp_pos_info_set_black_king_side_castling_right($info, 1);
	_cp_pos_info_set_black_queen_side_castling_right($info, 1);
	_cp_pos_info_set_to_move($info, CP_WHITE);
	_cp_pos_info_set_en_passant($info, 0);
	_cp_pos_info_set_halfmove_clock($info, 0);
	cp_pos_info($self) = $info;
	
	return $self;
}

sub newFromFEN {
	my ($class, $fen, $relaxed) = @_;

	my ($pieces, $color, $castling, $ep_square, $hmc, $moveno)
			= split /[ \t]+/, $fen;
	$moveno = 1 if !defined $moveno;
	$hmc = 0 if !defined $hmc;
	$ep_square = '-' if !defined $ep_square;
	$castling = '-' if !defined $castling;

	if (!(defined $pieces && defined $color)) {
		die __"Illegal FEN: Incomplete.\n";
	}

	my @ranks = split '/', $pieces;
	die __"Illegal FEN: FEN does not have exactly eight ranks.\n"
		if @ranks != 8;
	
	my $w_pieces = 0;
	my $b_pieces = 0;
	my $kings = 0;
	my $rooks = 0;
	my $knights = 0;
	my $bishops = 0;
	my $queens = 0;
	my $pawns = 0;

	my $material = 0;
	my $shift = 56;
	my $rankno = 7;
	foreach my $rank (@ranks) {
		my @chars = split '', $rank;
		foreach my $char (@chars) {
			if ('1' le $char && '8' ge $char) {
				$shift += $char;
				next;
			}

			my $mask = 1 << $shift;
			if ('P' eq $char) {
				$w_pieces |= $mask;
				$pawns |= $mask;
				$material += CP_PAWN_VALUE;
			} elsif ('p' eq $char) {
				$b_pieces |= $mask;
				$pawns |= $mask;
				$material -= CP_PAWN_VALUE;
			} elsif ('N' eq $char) {
				$w_pieces |= $mask;
				$knights |= $mask;
				$material += CP_KNIGHT_VALUE;
			} elsif ('n' eq $char) {
				$b_pieces |= $mask;
				$knights |= $mask;
				$material -= CP_KNIGHT_VALUE;
			} elsif ('B' eq $char) {
				$w_pieces |= $mask;
				$bishops |= $mask;
				$material += CP_BISHOP_VALUE;
			} elsif ('b' eq $char) {
				$b_pieces |= $mask;
				$bishops |= $mask;
				$material -= CP_BISHOP_VALUE;
			} elsif ('R' eq $char) {
				$w_pieces |= $mask;
				$rooks |= $mask;
				$material += CP_ROOK_VALUE;
			} elsif ('r' eq $char) {
				$b_pieces |= $mask;
				$rooks |= $mask;
				$material -= CP_ROOK_VALUE;
			} elsif ('Q' eq $char) {
				$w_pieces |= $mask;
				$queens |= $mask;
				$material += CP_QUEEN_VALUE;
			} elsif ('q' eq $char) {
				$b_pieces |= $mask;
				$queens |= $mask;
				$material -= CP_QUEEN_VALUE;
			} elsif ('K' eq $char) {
				$w_pieces |= $mask;
				$kings |= $mask;
			} elsif ('k' eq $char) {
				$b_pieces |= $mask;
				$kings |= $mask;
			} else {
				die __x("Illegal FEN: Illegal piece/number '{x}'.\n",
						x => $char);
			}
			++$shift;
		}

		if (($rankno-- << 3) + 8 != $shift) {
			die __x("Illegal FEN: Incomplete or overpopulated rank '{rank}'.\n",
				rank => $rank);
		}

		$shift -= 16;
	}

	my $self = bless [], $class;

	$self->[CP_POS_WHITE_PIECES] = $w_pieces;
	$self->[CP_POS_BLACK_PIECES] = $b_pieces;
	$self->[CP_POS_KINGS] = $kings;
	$self->[CP_POS_QUEENS] = $queens;
	$self->[CP_POS_ROOKS] = $rooks;
	$self->[CP_POS_BISHOPS] = $bishops;
	$self->[CP_POS_KNIGHTS] = $knights;
	$self->[CP_POS_PAWNS] = $pawns;

	my $pos_info = 0;
	_cp_pos_info_set_material($pos_info, $material);

	if ('w' eq lc $color) {
		_cp_pos_info_set_to_move($pos_info, CP_WHITE);
	} elsif ('b' eq lc $color) {
		_cp_pos_info_set_to_move($pos_info, CP_BLACK);
	} else {
		die __x"Illegal FEN: Side to move is neither 'w' nor 'b'.\n";
	}

	$self->__checkPieceCounts if !$relaxed;

	if ($castling ne '-' && $castling !~ /^K?Q?k?q?$/) {
		die __x("Illegal FEN: Illegal castling rights '{state}'.\n",
				state => $castling);
	}

	if ($castling =~ /K/) {
		$self->__checkCastlingState(CP_G1);
		_cp_pos_info_set_white_king_side_castling_right($pos_info, 1);
	}
	if ($castling =~ /Q/) {
		$self->__checkCastlingState(CP_C1);
		_cp_pos_info_set_white_queen_side_castling_right($pos_info, 1);
	}

	if ($castling =~ /k/) {
		$self->__checkCastlingState(CP_G8);
		_cp_pos_info_set_black_king_side_castling_right($pos_info, 1);
	}
	if ($castling =~ /q/) {
		$self->__checkCastlingState(CP_C8);
		_cp_pos_info_set_black_queen_side_castling_right($pos_info, 1);
	}

	cp_pos_info($self) = $pos_info;

	my $to_move = cp_pos_info_to_move($pos_info);
	$pos_info = $self->__checkEnPassantState($ep_square, $to_move, $pos_info);

	if ($hmc !~ /^0|[1-9][0-9]*$/) {
		$hmc = 0;
	}

	_cp_pos_info_set_halfmove_clock($pos_info, $hmc);

	# This is not redundant! Without it, the Zobrist key does not get calculated
	# correctly.
	cp_pos_info($self) = $pos_info;

	if ($moveno !~ /^[1-9][0-9]*$/) {
		$moveno = 1;
	}

	if ($to_move == CP_WHITE) {
			$self->[CP_POS_HALFMOVES] = ($moveno - 1) << 1;
	} else {
			$self->[CP_POS_HALFMOVES] = (($moveno - 1) << 1) + 1;
	}

	$self->__checkIllegalCheck($to_move) if !$relaxed;

	return $self;
}

sub __checkIllegalCheck {
	my ($self, $to_move) = @_;

	# Check whether the other side's king is in chess.
	my $king_index = $to_move == CP_WHITE ? CP_POS_BLACK_PIECES : CP_POS_WHITE_PIECES;
	my $king_bb = $self->[CP_POS_KINGS] & $self->[$king_index];
	my $king_shift = cp_bitboard_count_trailing_zbits $king_bb;

	if ($to_move == CP_WHITE) {
		if (_cp_pos_color_attacked $self, CP_BLACK, $king_shift) {
			die __"Illegal FEN: side not to move is in check!\n";
		}
	} else {
		if (_cp_pos_color_attacked $self, CP_WHITE, $king_shift) {
			die __"Illegal FEN: side not to move is in check!\n";
		}
	}

	return $self;
}

sub __checkPieceCounts {
	my ($self, $pos_info) = @_;

	my $to_move = cp_pos_info_to_move $pos_info;

	my $kings = $self->[CP_POS_KINGS];
	my $w_pieces = $self->[CP_POS_WHITE_PIECES];
	my $num_white_kings;
	cp_bitboard_popcount $w_pieces & $kings, $num_white_kings;
	if ($num_white_kings != 1) {
		die __"Illegal FEN: White must have exactly one king.\n";
	}

	my $b_pieces = $self->[CP_POS_BLACK_PIECES];
	my $num_black_kings;
	cp_bitboard_popcount $b_pieces & $kings, $num_black_kings;
	if ($num_black_kings != 1) {
		die __"Illegal FEN: Black must have exactly one king.\n";
	}

	my $pawns = $self->[CP_POS_PAWNS];

	# Pawn on 1st or 8th rank?
	if ($pawns & (CP_1_MASK | CP_8_MASK)) {
		die __"Illegal FEN: There can be no pawns on the first or eighth rank.\n";
	}

	my $num_white_pawns;
	cp_bitboard_popcount $w_pieces & $pawns, $num_white_pawns;
	if ($num_white_pawns > 8) {
		die __x("Illegal FEN: {colour} has too many {pieces}.\n",
			colour => __"White", pieces => __"pawns");
	}

	my $num_black_pawns;
	cp_bitboard_popcount $b_pieces & $pawns, $num_black_pawns;
	if ($num_black_pawns > 8) {
		die __x("Illegal FEN: {colour} has too many {pieces}.\n",
			colour => __"Black", pieces => __"pawns");
	}

	my $max_white_promotions = 8 - $num_white_pawns;
	my $max_black_promotions = 8 - $num_black_pawns;

	$self->__checkPromotionConsistency(
		\$max_white_promotions,
		__"queens",
		CP_WHITE, $self->[CP_POS_QUEENS], 1,
	);

	$self->__checkPromotionConsistency(
		\$max_black_promotions,
		__"queens",
		CP_BLACK, $self->[CP_POS_QUEENS], 1,
	);

	$self->__checkPromotionConsistency(
		\$max_white_promotions,
		__"rooks",
		CP_WHITE, $self->[CP_POS_ROOKS], 2,
	);

	$self->__checkPromotionConsistency(
		\$max_black_promotions,
		__"rooks",
		CP_BLACK, $self->[CP_POS_ROOKS], 2,
	);

	$self->__checkPromotionConsistency(
		\$max_white_promotions,
		__"bishops",
		CP_WHITE, $self->[CP_POS_BISHOPS], 2,
	);

	$self->__checkPromotionConsistency(
		\$max_black_promotions,
		__"bishops",
		CP_BLACK, $self->[CP_POS_BISHOPS], 2,
	);

	$self->__checkPromotionConsistency(
		\$max_white_promotions,
		__"knights",
		CP_WHITE, $self->[CP_POS_KNIGHTS], 2,
	);

	$self->__checkPromotionConsistency(
		\$max_black_promotions,
		__"knights",
		CP_BLACK, $self->[CP_POS_KNIGHTS], 2,
	);

	return $self;
}

sub __checkPromotionConsistency {
	my ($self, $max_promotions, $piece_name, $to_move, $pieces, $initial_count) = @_;

	my $all_pieces = $to_move == CP_WHITE ?
		$self->[CP_POS_WHITE_PIECES]
		: $self->[CP_POS_BLACK_PIECES];
	my $colour_name = $to_move == CP_WHITE ? __"White" : __"Black";

	my $num_pieces;
	cp_bitboard_popcount $all_pieces & $pieces, $num_pieces;

	$$max_promotions -= $num_pieces - $initial_count;
	if ($$max_promotions < 0) {
		die __x("Illegal FEN: {colour} has too many {pieces}.\n",
			colour => $colour_name, pieces => $piece_name);
	}

	return $self;
}

sub __checkEnPassantState {
	my ($self, $ep_square, $to_move, $pos_info) = @_;

	if ('-' eq $ep_square) {
		_cp_pos_info_set_en_passant($pos_info, 0);
	} elsif ($to_move == CP_WHITE) {
		if ($ep_square !~ /^[a-h]6$/) {
			die __x("Illegal FEN: White to move and en-passant square '{square}' is not on 6th rank.\n",
				square => $ep_square);
		}

		my $ep_shift = $self->squareToShift($ep_square);
		if ((1 << ($ep_shift - 8)) & $self->[CP_POS_BLACK_PIECES]
		    & $self->[CP_POS_PAWNS]) {
			_cp_pos_info_set_en_passant $pos_info, ((1 << 3) | ($ep_shift & 0x7))
		}
	} elsif ($to_move == CP_BLACK) {
		if ($ep_square !~ /^[a-h]3$/) {
			die __x("Illegal FEN: Black to move and en-passant square '{square}' is not on 3rd rank.\n",
				square => $ep_square);
		}
		my $ep_shift = $self->squareToShift($ep_square);
		if ((1 << ($ep_shift + 8)) & $self->[CP_POS_WHITE_PIECES]
		    & $self->[CP_POS_PAWNS]) {
			_cp_pos_info_set_en_passant $pos_info, ((1 << 3) | ($ep_shift & 0x7))
		}
	}

	return $pos_info;
}

sub __checkCastlingState {
	my ($self, $king_destination) = @_;

	my $is_white = $king_destination < CP_A2;
	my $king_square = $is_white ? CP_E1 : CP_E8;
	my $rook_square;
	if ($king_destination == CP_G1) {
		$rook_square = CP_H1;
	} elsif ($king_destination == CP_C1) {
		$rook_square = CP_A1;
	} elsif ($king_destination == CP_G8) {
		$rook_square = CP_H8;
	} else {
		$rook_square = CP_A8;
	}
	my $my_pieces = $is_white ? $self->[CP_POS_WHITE_PIECES] : $self->[CP_POS_BLACK_PIECES];

	if (($my_pieces & $self->[CP_POS_KINGS]) != (1 << $king_square)) {
		die __"Illegal castling rights: king not on initial square!\n";
	}

	if (!($my_pieces & $self->[CP_POS_ROOKS] & (1 << $rook_square))) {
		die __"Illegal castling rights: rook not on initial square!\n";
	}

	return $self;
}

sub pseudoLegalMoves {
	my ($self) = @_;

	my $pos_info = cp_pos_info $self;
	my $to_move = cp_pos_info_to_move $pos_info;
	my $my_pieces = $self->[CP_POS_WHITE_PIECES + $to_move];
	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$to_move];
	my $occupancy = $my_pieces | $her_pieces;
	my $empty = ~$occupancy;

	my (@moves, $target_mask, $base_move);

	# Generate king moves.  We take advantage of the fact that there is always
	# exactly one king of each color on the board.  So there is no need for a
	# loop.
	my $king_mask = $my_pieces & cp_pos_kings $self;

	my $from = cp_bitboard_count_isolated_trailing_zbits $king_mask;

	$base_move = ($from << 6 | CP_KING << 15);

	$target_mask = ~$my_pieces & $king_attack_masks[$from];

	_cp_moves_from_mask $target_mask, @moves, $base_move;

	# Generate castlings.
	# Mask out the castling rights for the side to move.
	my $castling_rights = ($pos_info >> ($to_move << 1)) & 0x3;
	if ($castling_rights) {
		my ($king_from, $king_from_mask, $king_side_crossing_mask,
			$king_side_dest_shift,
			$queen_side_crossing_mask, $queen_side_dest_shift,
			$queen_side_rook_crossing_mask)
			= @{$castling_aux_data[$to_move]};
		if ($king_mask & $king_from_mask) {
			if (($castling_rights & 0x1)
				&& !(((1 << $king_side_dest_shift) | $king_side_crossing_mask)
					& $occupancy)) {
				push @moves, ($king_from << 6 | CP_KING << 15)
					| $king_side_dest_shift;
			}
			if (($castling_rights & 0x2)
			    && (!(($queen_side_crossing_mask
			           | $queen_side_rook_crossing_mask
				       | (1 << $queen_side_dest_shift))
				      & $occupancy))) {
				push @moves, ($king_from << 6 | CP_KING << 15)
					| $queen_side_dest_shift;
			}
		}
	}

	# Generate knight moves.
	my $knight_mask = $my_pieces & cp_pos_knights $self;
	while ($knight_mask) {
		my $from = cp_bitboard_count_trailing_zbits $knight_mask;

		$base_move = ($from << 6 | CP_KNIGHT << 15);
	
		$target_mask = ~$my_pieces & $knight_attack_masks[$from];

		_cp_moves_from_mask $target_mask, @moves, $base_move;

		$knight_mask = cp_bitboard_clear_least_set $knight_mask;
	}

	# Generate bishop moves.
	my $bishop_mask = $my_pieces & cp_pos_bishops $self;
	while ($bishop_mask) {
		my $from = cp_bitboard_count_trailing_zbits $bishop_mask;

		$base_move = ($from << 6 | CP_BISHOP << 15);
	
		$target_mask = cp_mm_bmagic($from, $occupancy) & ($empty | $her_pieces);

		_cp_moves_from_mask $target_mask, @moves, $base_move;

		$bishop_mask = cp_bitboard_clear_least_set $bishop_mask;
	}

	# Generate rook moves.
	my $rook_mask = $my_pieces & cp_pos_rooks $self;
	while ($rook_mask) {
		my $from = cp_bitboard_count_trailing_zbits $rook_mask;

		$base_move = ($from << 6 | CP_ROOK << 15);
	
		$target_mask = cp_mm_rmagic($from, $occupancy) & ($empty | $her_pieces);

		_cp_moves_from_mask $target_mask, @moves, $base_move;

		$rook_mask = cp_bitboard_clear_least_set $rook_mask;
	}

	# Generate queen moves.
	my $queen_mask = $my_pieces & cp_pos_queens $self;
	while ($queen_mask) {
		my $from = cp_bitboard_count_trailing_zbits $queen_mask;

		$base_move = ($from << 6 | CP_QUEEN << 15);
	
		$target_mask = 
			(cp_mm_rmagic($from, $occupancy)
				| cp_mm_bmagic($from, $occupancy))
			& ($empty | $her_pieces);

		_cp_moves_from_mask $target_mask, @moves, $base_move;

		$queen_mask = cp_bitboard_clear_least_set $queen_mask;
	}

	# Generate pawn moves.
	my ($regular_mask, $double_mask, $promotion_mask, $offset) =
		@{$pawn_aux_data[$to_move]};

	my ($pawn_single_masks, $pawn_double_masks, $pawn_capture_masks) = 
		@{$pawn_masks[$to_move]};

	my $pawns = cp_pos_pawns $self;

	my $pawn_mask;

	my $ep = cp_pos_info_en_passant $pos_info;
	my $ep_shift;
	my $ep_target_mask;
	if ($ep) {
		$ep_shift = cp_en_passant_file_to_shift($ep, $to_move);
		$ep_target_mask = 1 << $ep_shift; 
	} else {
		$ep_shift = $ep_target_mask = 0;
	}

	# Pawn single steps and captures w/o promotions.
	$pawn_mask = $my_pieces & $pawns & $regular_mask;
	while ($pawn_mask) {
		my $from = cp_bitboard_count_trailing_zbits $pawn_mask;

		$base_move = ($from << 6 | CP_PAWN << 15);
		$target_mask = ($pawn_single_masks->[$from] & $empty)
			| ($pawn_capture_masks->[$from] & ($her_pieces | $ep_target_mask));
		_cp_moves_from_mask $target_mask, @moves, $base_move;
		$pawn_mask = cp_bitboard_clear_least_set $pawn_mask;
	}

	# Pawn double steps.
	$pawn_mask = $my_pieces & $pawns & $double_mask;
	while ($pawn_mask) {
		my $from = cp_bitboard_count_trailing_zbits $pawn_mask;
		my $cross_mask = $pawn_single_masks->[$from] & $empty;

		if ($cross_mask) {
			$target_mask = $pawn_double_masks->[$from] & $empty;
			if ($target_mask) {
				my $to = $from + ($offset << 1);
				push @moves, ($from << 6) | $to | CP_PAWN << 15;
			}
		}
		$pawn_mask = cp_bitboard_clear_least_set $pawn_mask;
	}

	# Pawn promotions including captures.
	$pawn_mask = $my_pieces & $pawns & ~$regular_mask;
	while ($pawn_mask) {
		my $from = cp_bitboard_count_trailing_zbits $pawn_mask;

		$base_move = ($from << 6 | CP_PAWN << 15);
		$target_mask = ($pawn_single_masks->[$from] & $empty)
			| ($pawn_capture_masks->[$from] & ($her_pieces | $ep_target_mask));
		_cp_promotion_moves_from_mask $target_mask, @moves, $base_move;
		$pawn_mask = cp_bitboard_clear_least_set $pawn_mask;
	}

	return @moves;
}

sub pseudoLegalAttacks {
	my ($self) = @_;

	my $pos_info = cp_pos_info $self;
	my $to_move = cp_pos_info_to_move $pos_info;
	my $my_pieces = $self->[CP_POS_WHITE_PIECES + $to_move];
	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$to_move];
	my $occupancy = $my_pieces | $her_pieces;
	my $empty = ~$occupancy;

	my (@moves, $target_mask, $base_move);

	# Generate king moves.  We take advantage of the fact that there is always
	# exactly one king of each color on the board.  So there is no need for a
	# loop.
	my $king_mask = $my_pieces & cp_pos_kings $self;

	my $from = cp_bitboard_count_isolated_trailing_zbits $king_mask;

	$base_move = ($from << 6 | CP_KING << 15);

	$target_mask = $her_pieces & $king_attack_masks[$from];

	_cp_moves_from_mask $target_mask, @moves, $base_move;

	# Generate knight moves.
	my $knight_mask = $my_pieces & cp_pos_knights $self;
	while ($knight_mask) {
		my $from = cp_bitboard_count_trailing_zbits $knight_mask;

		$base_move = ($from << 6 | CP_KNIGHT << 15);
	
		$target_mask = $her_pieces & $knight_attack_masks[$from];

		_cp_moves_from_mask $target_mask, @moves, $base_move;

		$knight_mask = cp_bitboard_clear_least_set $knight_mask;
	}

	# Generate bishop moves.
	my $bishop_mask = $my_pieces & cp_pos_bishops $self;
	while ($bishop_mask) {
		my $from = cp_bitboard_count_trailing_zbits $bishop_mask;

		$base_move = ($from << 6 | CP_BISHOP << 15);
	
		$target_mask = cp_mm_bmagic($from, $occupancy) & $her_pieces;

		_cp_moves_from_mask $target_mask, @moves, $base_move;

		$bishop_mask = cp_bitboard_clear_least_set $bishop_mask;
	}

	# Generate rook moves.
	my $rook_mask = $my_pieces & cp_pos_rooks $self;
	while ($rook_mask) {
		my $from = cp_bitboard_count_trailing_zbits $rook_mask;

		$base_move = ($from << 6 | CP_ROOK << 15);
	
		$target_mask = cp_mm_rmagic($from, $occupancy) & $her_pieces;

		_cp_moves_from_mask $target_mask, @moves, $base_move;

		$rook_mask = cp_bitboard_clear_least_set $rook_mask;
	}

	# Generate queen moves.
	my $queen_mask = $my_pieces & cp_pos_queens $self;
	while ($queen_mask) {
		my $from = cp_bitboard_count_trailing_zbits $queen_mask;

		$base_move = ($from << 6 | CP_QUEEN << 15);
	
		$target_mask = 
			(cp_mm_rmagic($from, $occupancy)
				| cp_mm_bmagic($from, $occupancy))
			& $her_pieces;

		_cp_moves_from_mask $target_mask, @moves, $base_move;

		$queen_mask = cp_bitboard_clear_least_set $queen_mask;
	}

	# Generate pawn moves.
	my ($regular_mask, $double_mask, $promotion_mask, $offset) =
		@{$pawn_aux_data[$to_move]};

	my ($pawn_single_masks, $pawn_double_masks, $pawn_capture_masks) = 
		@{$pawn_masks[$to_move]};

	my $pawns = cp_pos_pawns $self;

	my $pawn_mask;

	my $ep = cp_pos_info_en_passant $pos_info;
	my ($ep_shift, $ep_target_mask);
	if ($ep) {
		$ep_shift = cp_en_passant_file_to_shift($ep, $to_move);
		$ep_target_mask = 1 << $ep_shift; 
	} else {
		$ep_shift = $ep_target_mask = 0;
	}

	# Pawn captures w/o promotions.
	$pawn_mask = $my_pieces & $pawns & $regular_mask;
	while ($pawn_mask) {
		my $from = cp_bitboard_count_trailing_zbits $pawn_mask;

		$base_move = ($from << 6 | CP_PAWN << 15);
		$target_mask = ($pawn_capture_masks->[$from] & ($her_pieces | $ep_target_mask));
		_cp_moves_from_mask $target_mask, @moves, $base_move;
		$pawn_mask = cp_bitboard_clear_least_set $pawn_mask;
	}

	# Pawn promotions including captures.
	$pawn_mask = $my_pieces & $pawns & ~$regular_mask;
	while ($pawn_mask) {
		my $from = cp_bitboard_count_trailing_zbits $pawn_mask;

		$base_move = ($from << 6 | CP_PAWN << 15);
		$target_mask = ($pawn_single_masks->[$from] & $empty)
			| ($pawn_capture_masks->[$from] & ($her_pieces | $ep_target_mask));
		_cp_promotion_moves_from_mask $target_mask, @moves, $base_move;
		$pawn_mask = cp_bitboard_clear_least_set $pawn_mask;
	}

	return @moves;
}

# FIXME! Make this a macro!
sub __update {
	my ($self) = @_;

	# Update king's shift.
	my $pos_info = cp_pos_info($self);

	cp_pos_info($self) = $pos_info;
}

sub attacked {
	my ($self, $shift) = @_;

	return _cp_pos_color_attacked $self, cp_pos_to_move($self), $shift;
}

sub moveAttacked {
	my ($self, $move, $pseudo_legal) = @_;

	if ($move =~ /[a-z]/i) {
		$move = $self->parseMove($move, $pseudo_legal);
	}

	my ($from, $to) = (cp_move_from($move), cp_move_to($move));
	return _cp_pos_move_attacked $self, $from, $to;
}

sub moveGivesCheck {
	my ($self, $move) = @_;

	# FIXME! Check that all of these variables are really needed at least twice!
	my $pos_info = cp_pos_info $self;
	my $from = cp_move_from $move;
	my $from_mask = 1 << $from;
	my $to = cp_move_to $move;
	my $to_mask = 1 << $to;

	my $piece = cp_move_piece $move;
	my $to_move = cp_pos_info_to_move $pos_info;
	my $my_pieces = $self->[CP_POS_WHITE_PIECES + $to_move];
	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$to_move];
	my $her_king_mask = $self->[CP_POS_KINGS] & $her_pieces;
	my $her_king_shift = cp_bitboard_count_isolated_trailing_zbits $her_king_mask;
	my $occupancy = $self->[CP_POS_WHITE_PIECES] | $self->[CP_POS_BLACK_PIECES];
	my $bsliders = $my_pieces
			& ($self->[CP_POS_BISHOPS] | $self->[CP_POS_QUEENS]);
	my $rsliders = $my_pieces
			& ($self->[CP_POS_ROOKS] | $self->[CP_POS_QUEENS]);
	my $ep = cp_pos_info_en_passant $pos_info;
	if ($ep) {
		my $ep_shift = cp_en_passant_file_to_shift($ep, $to_move);
		if ($piece == CP_PAWN && $ep_shift && $to == $ep_shift) {
			# Remove the captured piece, as well.
			$from_mask |= $ep_pawn_masks[$ep_shift];
		}
	}

	if (($piece == CP_PAWN)
	         && ($to_mask & $pawn_masks[!$to_move]->[2]->[$her_king_shift])) {
		return 1;
	} elsif (($piece == CP_KNIGHT)
	         && ($to_mask & $knight_attack_masks[$her_king_shift])) {
		# Direct knight check.
		return 1;
	} elsif (($piece == CP_BISHOP || $piece == CP_QUEEN)
	         && (cp_mm_bmagic($her_king_shift, $occupancy) & $to_mask)) {
		# Direct bishop/queen check.
		return 1;
	} elsif (($piece == CP_ROOK || $piece == CP_QUEEN)
	         && (cp_mm_rmagic($her_king_shift, $occupancy) & $to_mask)) {
		# Direct rook/queen check.
		return 1;
	} elsif ($piece == CP_KING && ((($from - $to) & 0x3) == 0x2)
		&& (cp_mm_rmagic($her_king_shift, $occupancy) & $castling_rook_to_mask[$to])) {
		return 1;
	} elsif (cp_mm_bmagic($her_king_shift, $occupancy ^ $from_mask)
		& (($my_pieces & ($self->[CP_POS_BISHOPS] | $self->[CP_POS_QUEENS]) & ~$from_mask))) {
		return 1;
	} elsif (cp_mm_rmagic($her_king_shift, $occupancy ^ $from_mask)
		& (($my_pieces & ($self->[CP_POS_ROOKS] | $self->[CP_POS_QUEENS]) & ~$from_mask))) {
		return 1;
	}

	return;
}

sub movePinned {
	my ($self, $move, $pseudo_legal) = @_;

	if ($move =~ /[a-z]/i) {
		$move = $self->parseMove($move, $pseudo_legal);
	}

	my $to_move = cp_pos_to_move $self;
	my $my_pieces = $self->[CP_POS_WHITE_PIECES + $to_move];
	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$to_move];
	my ($from, $to) = (cp_move_from($move), cp_move_to($move));

	my $kings_bb = cp_pos_kings($self)
		& ($to_move ? cp_pos_black_pieces($self) : cp_pos_white_pieces($self));
	my $king_shift = cp_bitboard_count_isolated_trailing_zbits($kings_bb);

	return _cp_pos_move_pinned $self, $from, $to, $king_shift, $my_pieces, $her_pieces;
}

sub moveEquivalent {
	my ($self, $m1, $m2) = @_;

	return cp_move_equivalent $m1, $m2;
}

sub moveSignificant {
	my ($self, $move) = @_;

	return cp_move_significant $move;
}

sub move {
	my ($self, $move) = @_;

	my @backup = @$self;

	my $pos_info = cp_pos_info $self;
	my ($from, $to, $promote, $piece) =
		(cp_move_from($move), cp_move_to($move), cp_move_promote($move),
		 cp_move_piece($move));

	my $to_move = cp_pos_info_to_move($pos_info);
	my $to_mask = 1 << $to;
	my $move_mask = (1 << $from) | $to_mask;
	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$to_move];

	my $old_castling = my $new_castling = cp_pos_info_castling_rights $pos_info;

	if ($piece == CP_KING) {
		# Castling?
		if ((($from - $to) & 0x3) == 0x2) {
			# Move the rook.
			my $rook_move_mask = $castling_rook_move_masks[$to];
			$self->[CP_POS_ROOKS] ^= $rook_move_mask;
			$self->[CP_POS_WHITE_PIECES + $to_move] ^= $rook_move_mask;
		}

		# Remove the castling rights.
		$new_castling &= ~(0x3 << ($to_move << 1));
	}

	# Remove castling rights if a rook moves from its original square or it
	# gets captured.  We simplify that by simply checking whether either the
	# start or the destination square is a1, h1, a8, or h8.
	$new_castling &= $castling_rights_rook_masks[$from];
	$new_castling &= $castling_rights_rook_masks[$to];

	my $captured = CP_NO_PIECE;
	my $captured_mask = 0;
	if ($to_mask & $her_pieces) {
		if ($to_mask & cp_pos_pawns($self)) {
			$captured = CP_PAWN;
		} elsif ($to_mask & cp_pos_knights($self)) {
			$captured = CP_KNIGHT;
		} elsif ($to_mask & cp_pos_bishops($self)) {
			$captured = CP_BISHOP;
		} elsif ($to_mask & cp_pos_rooks($self)) {
			$captured = CP_ROOK;
		} else {
			$captured = CP_QUEEN;
		}
		$captured_mask = 1 << $to;
	}

	my $is_ep;
	if ($piece == CP_PAWN) {
		my $ep = cp_pos_info_en_passant $pos_info;

		# Check en passant.
		if ($ep) {
			my $ep_shift = $ep ? cp_en_passant_file_to_shift($ep, $to_move) : 0;

			if ($ep_shift && $to == $ep_shift) {
				$captured_mask = $ep_pawn_masks[$ep_shift];
				$captured = CP_PAWN;
				$is_ep = 1;
			}
		}
		_cp_pos_info_set_halfmove_clock($pos_info, 0);
		if (_cp_pawn_double_step $from, $to) {
			_cp_pos_info_set_en_passant($pos_info, ((1 << 3) | ($from & 7)));
		} else {
			_cp_pos_info_set_en_passant($pos_info, 0);
		}
	} elsif ($her_pieces & $to_mask) {
		_cp_pos_info_set_halfmove_clock($pos_info, 0);
		_cp_pos_info_set_en_passant($pos_info, 0);
	} else {
		my $hmc = cp_pos_info_halfmove_clock($pos_info);
		_cp_pos_info_set_halfmove_clock($pos_info, $hmc + 1);
		_cp_pos_info_set_en_passant($pos_info, 0);
	}

	# Move all pieces involved.
	if ($captured != CP_NO_PIECE) {
		$self->[CP_POS_WHITE_PIECES + !$to_move] ^= $captured_mask;
		$self->[$captured] ^= $captured_mask;
		cp_move_set_captured($move, $captured);

	}

	$self->[CP_POS_WHITE_PIECES + $to_move] ^= $move_mask;
	$self->[$piece] ^= $move_mask;

	# It is better to overwrite the castling rights unconditionally because
	# it safes branches.  There is one edge case, where a pawn captures a
	# rook that is on its initial position.  In that case, the castling
	# rights may have to be updated.
	_cp_pos_info_set_castling $pos_info, $new_castling;

	if ($promote) {
		$self->[CP_POS_PAWNS] ^= $to_mask;
		$self->[$promote] ^= $to_mask;
	}

	cp_move_set_color($move, $to_move);
	cp_move_set_en_passant($move, $is_ep);

	++$self->[CP_POS_HALFMOVES];
	_cp_pos_info_set_to_move($pos_info, !$to_move);

	# The material balance is stored in the most signicant bits.  It is
	# already left-shifted 19 bits in the lookup table so that we can simply
	# add it.
	#
	# FIXME! Assemble the position info all at once instead of setting
	# individual fields.
	$pos_info += $material_deltas[$to_move | ($promote << 1) | ($captured << 4)];

	$self->[CP_POS_INFO] = $pos_info;

	unshift @backup, $move;

	return \@backup;
}

sub unmove {
	my ($self, $backup) = @_;

	shift @$backup; # The move.
	@$self = @$backup;

	return $self;
}

sub doMove {
	my ($self, $move) = @_;

	my @check_info = $self->inCheck;
	return if !$self->checkPseudoLegalMove($move, @check_info);

	return $self->move($move);
}

sub undoMove {
	&unmove;
}

sub bMagic {
	my ($self, $shift, $occupancy) = @_;

	return cp_mm_bmagic $shift, $occupancy;
}

sub rMagic {
	my ($self, $shift, $occupancy) = @_;

	return cp_mm_rmagic $shift, $occupancy;
}

# Position info methods.
sub castlingRights {
	my ($self) = @_;

	return cp_pos_castling_rights $self;
}

sub whiteKingSideCastlingRight {
	my ($self) = @_;

	return cp_pos_white_king_side_castling_right($self);
}

sub whiteQueenSideCastlingRight {
	my ($self) = @_;

	return cp_pos_white_queen_side_castling_right($self);
}

sub blackKingSideCastlingRight {
	my ($self) = @_;

	return cp_pos_black_king_side_castling_right($self);
}

sub blackQueenSideCastlingRight {
	my ($self) = @_;

	return cp_pos_black_queen_side_castling_right($self);
}

sub toMove {
	my ($self) = @_;

	return cp_pos_to_move($self);
}

sub enPassant {
	my ($self) = @_;

	return cp_pos_en_passant($self);
}

sub enPassantShift {
	my ($self) = @_;

	my $ep = cp_pos_en_passant($self);

	return $ep ? cp_en_passant_file_to_shift($ep, $self->toMove) : 0;
}

sub material {
	my ($self) = @_;

	return cp_pos_material($self);
}

# Move methods.
sub moveFrom {
	my (undef, $move) = @_;

	return cp_move_from $move;
}

sub moveSetFrom {
	my (undef, $move, $from) = @_;

	cp_move_set_from $move, $from;

	return $move;
}

sub moveTo {
	my (undef, $move) = @_;

	return cp_move_to $move;
}

sub moveSetTo {
	my (undef, $move, $to) = @_;

	cp_move_set_from $move, $to;

	return $move;
}

sub movePromote {
	my (undef, $move) = @_;

	return cp_move_promote $move;
}

sub moveSetPromote {
	my (undef, $move, $promote) = @_;

	cp_move_set_promote $move, $promote;

	return $move;
}

sub movePiece {
	my (undef, $move) = @_;

	return cp_move_piece $move;
}

sub moveSetPiece {
	my (undef, $move, $piece) = @_;

	cp_move_set_piece $move, $piece;

	return $move;
}

sub moveCaptured {
	my (undef, $move) = @_;

	return cp_move_captured $move;
}

sub moveSetCaptured {
	my (undef, $move, $piece) = @_;

	cp_move_set_captured $move, $piece;

	return $move;
}

sub moveColor {
	my (undef, $move) = @_;

	return cp_move_color $move;
}

sub moveSetColor {
	my (undef, $move, $color) = @_;

	cp_move_set_color $move, $color;

	return $move;
}

sub moveEnPassant {
	my (undef, $move) = @_;

	return cp_move_en_passant $move;
}

sub moveSetEnPassant {
	my (undef, $move, $flag) = @_;

	cp_move_set_en_passant $move, $flag;

	return $move;
}

sub moveCoordinateNotation {
	my (undef, $move) = @_;

	return cp_move_coordinate_notation $move;
}

sub LAN {
	&moveCoordinateNotation;
}

sub SEE {
	my ($self, $move) = @_;

	my $to = cp_move_to $move;
	my $from = cp_move_from $move;
	my $not_from_mask = ~(1 << ($from));
	my $pos_info = cp_pos_info($self);
	my $to_move = cp_pos_info_to_move($pos_info);
	my $ep = cp_pos_info_en_passant($pos_info);
	my $ep_shift = $ep ? cp_en_passant_file_to_shift($ep, $to_move) : 0;
	my $move_is_ep = ($ep_shift && $to == $ep_shift
		&& cp_move_piece($move) == CP_PAWN);
	my $white = cp_pos_white_pieces($self);
	my $black = cp_pos_black_pieces($self);
	my $occupancy = $white | $black;

	# FIXME! This is possible without a branch.
	if ($move_is_ep) {
		$occupancy &= ~$ep_pawn_masks[$to];
	}

	my $to_mask = 1 << $to;
	my $maybe_promote = $to_mask & (CP_1_MASK | CP_8_MASK);
	my $shifted_pawn_value = ($maybe_promote
		? CP_QUEEN_VALUE - CP_PAWN_VALUE
		: CP_PAWN_VALUE) << 8;

	my (@white_attackers, @black_attackers, $mask);

	# Now generate all squares that are attacking the target square.  This is
	# done in order of piece value.  We silently assume here this relationship:
	#
	#   P < N <= B < R < Q (< K)
	#
	# But this does not seem to be any restriction.
	#
	# For each attack vector we store the piece value shifted 8 bits to the
	# right ORed with the from shift.

	my $pawns = cp_pos_pawns($self);
	# We have to use the opposite pawn masks because we want to get the
	# attacking squares of the target square, and not the attacked squares
	# of the start square.
	$mask = $pawn_masks[CP_BLACK]->[2]->[$to] & $pawns
		& $white & $not_from_mask;
	while ($mask) {
		my $afrom = cp_bitboard_count_trailing_zbits $mask;

		push @white_attackers, ($afrom | $shifted_pawn_value);
		$mask = cp_bitboard_clear_least_set($mask);
	}
	$mask = $pawn_masks[CP_WHITE]->[2]->[$to] & $pawns
		& $black & $not_from_mask;
	while ($mask) {
		my $afrom = cp_bitboard_count_trailing_zbits $mask;

		push @black_attackers, ($afrom | $shifted_pawn_value);
		$mask = cp_bitboard_clear_least_set($mask);
	}

	my $knights = cp_pos_knights($self);
	my $shifted_knight_value = CP_KNIGHT_VALUE << 8;
	$mask = $knight_attack_masks[$to] & $knights & $white & $not_from_mask;
	while ($mask) {
		my $afrom = cp_bitboard_count_trailing_zbits $mask;

		push @white_attackers, ($afrom | $shifted_knight_value);
		$mask = cp_bitboard_clear_least_set($mask);
	}
	$mask = $knight_attack_masks[$to] & $knights & $black & $not_from_mask;
	while ($mask) {
		my $afrom = cp_bitboard_count_trailing_zbits $mask;

		push @black_attackers, ($afrom | $shifted_knight_value);
		$mask = cp_bitboard_clear_least_set($mask);
	}

	my $bishop_mask = cp_mm_bmagic($to, $occupancy) & $not_from_mask;
	my $rook_mask = cp_mm_rmagic($to, $occupancy) & $not_from_mask;
	my $queen_mask = $bishop_mask | $rook_mask;

	my $bishops = cp_pos_bishops($self);
	my $shifted_bishop_value = CP_BISHOP_VALUE << 8;
	$mask = $bishop_mask & $bishops & $white;
	while ($mask) {
		my $afrom = cp_bitboard_count_trailing_zbits $mask;

		push @white_attackers, ($afrom | $shifted_bishop_value);
		$mask = cp_bitboard_clear_least_set($mask);
	}
	$mask = $bishop_mask & $bishops & $black;
	while ($mask) {
		my $afrom = cp_bitboard_count_trailing_zbits $mask;

		push @black_attackers, ($afrom | $shifted_bishop_value);
		$mask = cp_bitboard_clear_least_set($mask);
	}

	my $rooks = cp_pos_rooks($self);
	my $shifted_rook_value = CP_ROOK_VALUE << 8;
	$mask = $rook_mask & $rooks & $white;
	while ($mask) {
		my $afrom = cp_bitboard_count_trailing_zbits $mask;

		push @white_attackers, ($afrom | $shifted_rook_value);
		$mask = cp_bitboard_clear_least_set($mask);
	}
	$mask = $rook_mask & $rooks & $black;
	while ($mask) {
		my $afrom = cp_bitboard_count_trailing_zbits $mask;

		push @black_attackers, ($afrom | $shifted_rook_value);
		$mask = cp_bitboard_clear_least_set($mask);
	}

	my $queens = cp_pos_queens($self);
	my $shifted_queen_value = CP_QUEEN_VALUE << 8;
	$mask = $queen_mask & $queens & $white;
	while ($mask) {
		my $afrom = cp_bitboard_count_trailing_zbits $mask;

		push @white_attackers, ($afrom | $shifted_queen_value);
		$mask = cp_bitboard_clear_least_set($mask);
	}
	$mask = $queen_mask & $queens & $black;
	while ($mask) {
		my $afrom = cp_bitboard_count_trailing_zbits $mask;

		push @black_attackers, ($afrom | $shifted_queen_value);
		$mask = cp_bitboard_clear_least_set($mask);
	}

	my $kings = cp_pos_kings($self);
	my $shifted_king_value = 9999 << 8;
	$mask = $king_attack_masks[$to] & $kings & $white;
	if ($mask) {
		my $afrom = cp_bitboard_count_isolated_trailing_zbits $mask;

		push @white_attackers, ($afrom | $shifted_king_value);
	}
	$mask = $king_attack_masks[$to] & $kings & $black;
	if ($mask) {
		my $afrom = cp_bitboard_count_isolated_trailing_zbits $mask;

		push @black_attackers, ($afrom | $shifted_king_value);
	}

	$occupancy &= $not_from_mask;

	my $promote = cp_move_promote($move);

	my $captured;
	if ($move_is_ep || ($to_mask & $pawns)) {
		$captured = CP_PAWN;
	} elsif ($to_mask & $knights) {
		$captured = CP_KNIGHT;
	} elsif ($to_mask & $bishops) {
		$captured = CP_BISHOP;
	} elsif ($to_mask & $rooks) {
		$captured = CP_ROOK;
	} elsif ($to_mask & $queens) {
		$captured = CP_QUEEN;
	} else {
		# For SEE purposes we have to assume that we do not underpromote.
		$captured = CP_NO_PIECE;
	}

	my $side_to_move = !$to_move;
	my @gain = ($piece_values[$captured]);
	my $attacker_value = $piece_values[cp_move_piece($move)];
	if ($promote) {
		$attacker_value = $piece_values[$promote];
		$gain[0] += $attacker_value - CP_PAWN_VALUE;
	}

	my $sliding_mask = $bishops | $rooks | $queens;
	my $sliding_rooks_mask = $rooks | $queens;
	my $sliding_bishops_mask = $bishops | $queens;
	my $depth = 0;
	my @attackers = (\@white_attackers, \@black_attackers);

	while (1) {
		++$depth;

		# FIXME! Rather remember the last gain in order to save an array
		# dereferencing.
		$gain[$depth] = $attacker_value - $gain[$depth - 1];

		# Add x-ray attackers.
		my $obscured_mask = $obscured_masks[$from]->[$to];
		if ($sliding_mask & $obscured_mask) {
			# This is the slow part.
			my $is_rook_move = (($from & 7) == ($to & 7))
				|| (($from & 56) == ($to & 56));
			my $piece;
			if ($is_rook_move && ($obscured_mask & $sliding_rooks_mask)) {
				$mask = $sliding_rooks_mask & cp_mm_rmagic($to, $occupancy);
				$piece = CP_ROOK;
			} elsif (!$is_rook_move && ($obscured_mask & $sliding_bishops_mask)) {
				$mask = $sliding_bishops_mask & cp_mm_bmagic($to, $occupancy);
				$piece = CP_BISHOP;
			}
			if ($obscured_mask & $mask) {
				my $piece_mask;

				if ($from > $to) {
					$piece_mask = cp_bitboard_clear_but_most_set($obscured_mask & $mask);
				} else {
					$piece_mask = cp_bitboard_clear_but_least_set($obscured_mask & $mask);
				}
				if ($piece_mask) {
					my $color;
					if ($piece_mask & $white) {
						$color = CP_WHITE;
					} else {
						$color = CP_BLACK;
					}
					if ($piece_mask & $queens) {
						$piece = CP_QUEEN;
					}

					# Now insert the x-ray attacker into the list.  Since the
					# piece is encoded in the upper bytes, we can do a simple,
					# unmasked comparison.
					my $attackers_array = $attackers[$color];
					my $item = ($piece_values[$piece] << 8)
						| cp_bitboard_count_isolated_trailing_zbits($piece_mask);
					unshift @$attackers_array, $item;
					foreach my $i (0.. @$attackers_array - 2) {
						last if $attackers_array->[$i] <= $attackers_array->[$i + 1];
						($attackers_array->[$i], $attackers_array->[$i+1])
							= ($attackers_array->[$i + 1], $attackers_array->[$i]);
					}
				}
			}
		}

		my $attacker_def = shift @{$attackers[$side_to_move]};
		if (!$attacker_def) {
			last;
		}

		$attacker_value = $attacker_def >> 8;
		$from = $attacker_def & 0xff;

		# Can we prune?
		if (cp_max(-$gain[$depth - 1], $gain[$depth]) < 0) {
			last;
		}

		$occupancy -= (1 << $from);

		$side_to_move = !$side_to_move;
	}

	while (--$depth) {
		$gain[$depth - 1]= -(cp_max(-$gain[$depth - 1], $gain[$depth]));
	}

	return $gain[0];
}

sub parseMove {
	my ($self, $notation, $pseudo_legal) = @_;

	my $move;

	if ($notation =~ /^([a-h][1-8])([a-h][1-8])([qrbn])?$/) {
		$move = $self->__parseUCIMove(map { lc $_ } ($1, $2, $3));
	} else {
		$move = $self->__parseSAN($notation);
	}

	my $piece;
	my $from_mask = 1 << (cp_move_from $move);
	if ($from_mask & cp_pos_pawns($self)) {
		$piece = CP_PAWN;
	} elsif ($from_mask & cp_pos_knights($self)) {
		$piece = CP_KNIGHT;
	} elsif ($from_mask & cp_pos_bishops($self)) {
		$piece = CP_BISHOP;
	} elsif ($from_mask & cp_pos_rooks($self)) {
		$piece = CP_ROOK;
	} elsif ($from_mask & cp_pos_queens($self)) {
		$piece = CP_QUEEN;
	} elsif ($from_mask & cp_pos_kings($self)) {
		$piece = CP_KING;
	} else {
		require Carp;
		Carp::croak(__"Illegal move: start square is empty.\n");
	}

	cp_move_set_piece($move, $piece);

	my $captured = CP_NO_PIECE;
	my $to_mask = 1 << (cp_move_to $move);
	if ($to_mask & cp_pos_pawns($self)) {
		$captured = CP_PAWN;
	} elsif ($to_mask & cp_pos_knights($self)) {
		$captured = CP_KNIGHT;
	} elsif ($to_mask & cp_pos_bishops($self)) {
		$captured = CP_BISHOP;
	} elsif ($to_mask & cp_pos_rooks($self)) {
		$captured = CP_ROOK;
	} elsif ($to_mask & cp_pos_queens($self)) {
		$captured = CP_QUEEN;
	} elsif ($to_mask & cp_pos_kings($self)) {
		$captured = CP_KING;
	} elsif ($piece == CP_PAWN && $self->enPassant
	         && (cp_move_to($move) == $self->enPassantFileToShift($self->enPassant, $self->toMove))) {
		$captured = CP_PAWN;
		cp_move_set_en_passant $move, 1;
	}
	cp_move_set_captured $move, $captured;
	cp_move_set_color $move, $self->toMove;

	if (!$pseudo_legal) {
		foreach my $candidate ($self->legalMoves) {
			return $move if $candidate == $move;
		}

		die __"Illegal move!\n";
	}

	return $move;
}

sub __parseUCIMove {
	my ($class, $from_square, $to_square, $promote) = @_;

	my $move = 0;
	my $from = $class->squareToShift($from_square);
	my $to = $class->squareToShift($to_square);

	# There is no need for boundary checking. The regexes [a-h][1-8] used in
	# the callers are sufficient for that.

	cp_move_set_from($move, $from);
	cp_move_set_to($move, $to);

	if ($promote) {
		my %pieces = (
			q => CP_QUEEN,
			r => CP_ROOK,
			b => CP_BISHOP,
			n => CP_KNIGHT,
		);

		cp_move_set_promote($move, $pieces{lc $promote} or return);
	}

	return $move;
}

sub bitboardPopcount {
	my (undef, $bitboard) = @_;

	my $count;
	cp_bitboard_popcount $bitboard, $count;

	return $count;
}

sub bitboardClearLeastSet {
	my (undef, $bitboard) = @_;

	return cp_bitboard_clear_least_set $bitboard;
}

sub bitboardClearButLeastSet {
	my (undef, $bitboard) = @_;

	return cp_bitboard_clear_but_least_set $bitboard;
}

sub bitboardCountIsolatedTrailingZbits {
	my (undef, $bitboard) = @_;

	return cp_bitboard_count_isolated_trailing_zbits $bitboard;
}

sub bitboardCountTrailingZbits {
	my (undef, $bitboard) = @_;

	return cp_bitboard_count_trailing_zbits $bitboard;
}

sub bitboardMoreThanOneSet {
	my (undef, $bitboard) = @_;

	return cp_bitboard_more_than_one_set $bitboard;
}

sub gameOver {
	my ($self, $forcible) = @_;

	my $state = 0;

	my @legal = $self->legalMoves;
	if (!@legal) {
		$state |= CP_GAME_OVER;
		if ($self->inCheck) {
			if (CP_WHITE == cp_pos_to_move $self) {
				$state |= CP_GAME_BLACK_WINS;
			} else {
				$state |= CP_GAME_WHITE_WINS;
			}
		} else {
			$state |= CP_GAME_STALEMATE;
		}
	} elsif (100 <= cp_pos_halfmove_clock $self) {
		$state |= CP_GAME_OVER | CP_GAME_FIFTY_MOVES;
	} elsif ($self->insufficientMaterial($forcible)) {
		$state |= CP_GAME_OVER | CP_GAME_INSUFFICIENT_MATERIAL;
	}

	return $state;
}

sub signature {
	my ($self) = @_;

	my $signature = 0;
	my $piece_mask;

	my ($pawns, $knights, $bishops, $rooks, $queens, $kings, $white, $black)
		= @{$self}[CP_POS_PAWNS .. CP_POS_BLACK_PIECES];

	$piece_mask = $pawns & $white;
	while ($piece_mask) {
		my $shift = cp_bitboard_count_trailing_zbits $piece_mask;
		$signature ^= _cp_zk_lookup(CP_PAWN, CP_WHITE, $shift);
		$piece_mask = cp_bitboard_clear_least_set $piece_mask;
	}

	$piece_mask = $pawns & $black;
	while ($piece_mask) {
		my $shift = cp_bitboard_count_trailing_zbits $piece_mask;
		$signature ^= _cp_zk_lookup(CP_PAWN, CP_BLACK, $shift);
		$piece_mask = cp_bitboard_clear_least_set $piece_mask;
	}

	$piece_mask = $knights & $white;
	while ($piece_mask) {
		my $shift = cp_bitboard_count_trailing_zbits $piece_mask;
		$signature ^= _cp_zk_lookup(CP_KNIGHT, CP_WHITE, $shift);
		$piece_mask = cp_bitboard_clear_least_set $piece_mask;
	}

	$piece_mask = $knights & $black;
	while ($piece_mask) {
		my $shift = cp_bitboard_count_trailing_zbits $piece_mask;
		$signature ^= _cp_zk_lookup(CP_KNIGHT, CP_BLACK, $shift);
		$piece_mask = cp_bitboard_clear_least_set $piece_mask;
	}

	$piece_mask = $bishops & $white;
	while ($piece_mask) {
		my $shift = cp_bitboard_count_trailing_zbits $piece_mask;
		$signature ^= _cp_zk_lookup(CP_BISHOP, CP_WHITE, $shift);
		$piece_mask = cp_bitboard_clear_least_set $piece_mask;
	}

	$piece_mask = $bishops & $black;
	while ($piece_mask) {
		my $shift = cp_bitboard_count_trailing_zbits $piece_mask;
		$signature ^= _cp_zk_lookup(CP_BISHOP, CP_BLACK, $shift);
		$piece_mask = cp_bitboard_clear_least_set $piece_mask;
	}

	$piece_mask = $rooks & $white;
	while ($piece_mask) {
		my $shift = cp_bitboard_count_trailing_zbits $piece_mask;
		$signature ^= _cp_zk_lookup(CP_ROOK, CP_WHITE, $shift);
		$piece_mask = cp_bitboard_clear_least_set $piece_mask;
	}

	$piece_mask = $rooks & $black;
	while ($piece_mask) {
		my $shift = cp_bitboard_count_trailing_zbits $piece_mask;
		$signature ^= _cp_zk_lookup(CP_ROOK, CP_BLACK, $shift);
		$piece_mask = cp_bitboard_clear_least_set $piece_mask;
	}

	$piece_mask = $queens & $white;
	while ($piece_mask) {
		my $shift = cp_bitboard_count_trailing_zbits $piece_mask;
		$signature ^= _cp_zk_lookup(CP_QUEEN, CP_WHITE, $shift);
		$piece_mask = cp_bitboard_clear_least_set $piece_mask;
	}

	$piece_mask = $queens & $black;
	while ($piece_mask) {
		my $shift = cp_bitboard_count_trailing_zbits $piece_mask;
		$signature ^= _cp_zk_lookup(CP_QUEEN, CP_BLACK, $shift);
		$piece_mask = cp_bitboard_clear_least_set $piece_mask;
	}

	$piece_mask = $kings & $white;
	while ($piece_mask) {
		my $shift = cp_bitboard_count_trailing_zbits $piece_mask;
		$signature ^= _cp_zk_lookup(CP_KING, CP_WHITE, $shift);
		$piece_mask = cp_bitboard_clear_least_set $piece_mask;
	}

	$piece_mask = $kings & $black;
	while ($piece_mask) {
		my $shift = cp_bitboard_count_trailing_zbits $piece_mask;
		$signature ^= _cp_zk_lookup(CP_KING, CP_BLACK, $shift);
		$piece_mask = cp_bitboard_clear_least_set $piece_mask;
	}

	my $pos_info = cp_pos_info $self;

	my $ep = cp_pos_info_en_passant $pos_info;
	if ($ep) {
		$signature ^= $zk_ep_files[$ep & 7];
	}

	my $castling = cp_pos_info_castling_rights $pos_info;
	$signature ^= $zk_castling[$castling];

	if (cp_pos_info_to_move $pos_info) {
		$signature ^= $zk_color;
	}

	return $signature;
}

sub _zkPieces {
	return @zk_pieces;
}

sub _zkEpFiles {
	return @zk_ep_files;
}

sub _zkCastling {
	return @zk_castling
}

sub _zkColor {
	return $zk_color;
}

sub __zobristKeyLookup {
	my ($self, $piece, $color, $shift) = @_;

	return _cp_zk_lookup($piece, $color, $shift);
}

sub __zobristKeyLookupByIndex {
	my ($self, $index) = @_;

	return $zk_pieces[$index];
}

sub __dumpMove {
	my ($self, $move) = @_;

	my $bits = sprintf "move (0b%b): $move", $move;
	my $colour = cp_move_color($move) == CP_WHITE ? 'white' : 'black';
	$colour = sprintf "turn (0b%b): $colour", cp_move_color $move;
	my $to = cp_move_to($move);
	my $from = cp_move_from($move);
	my $from_bits = sprintf '0b%b', $from;
	my $to_bits = sprintf '0b%b', $to;
	my $from_square = "from ($from_bits): " . cp_shift_to_square $from;
	my $to_square = "to ($to_bits): " . cp_shift_to_square $to;
	my $piece = cp_move_piece $move;
	my $piece_bits = sprintf '0b%b', $piece;
	my $piece_char = "piece ($piece_bits): " . CP_PIECE_CHARS->[0]->[$piece];
	my $captured = cp_move_captured $move;
	my $captured_bits = sprintf '0b%b', $captured;
	my $captured_char = "captured ($captured_bits): " . CP_PIECE_CHARS->[0]->[$captured];
	my $promote = cp_move_promote $move;
	my $promote_bits = sprintf '0b%b', $promote;
	my $promote_char = "promote ($promote_bits): " . CP_PIECE_CHARS->[0]->[$promote];
	my $ep = (cp_move_en_passant $move) ? 'en passant: yes' : 'en passant no';
	my $ep_file;
	if ($ep) {
		my $file = chr(ord('a') + ($ep & 0x3));
		$ep_file = "en passant file: $file";
	} else {
		$ep_file = "en passant file: -";
	}
	return join "\n", $bits, $colour, $to_square, $from_square, $piece_char, $captured_char, $promote_char, $ep, $ep_file, '';
}

sub __zobristKeyDump {
	my ($self) = @_;

	my $output = "Pieces\n======\n\n";
	for (my $i = 0; $i < 768; ++$i) {
		$output .= sprintf '% 4u:', $i;
		my $s = $i + 128;
		my $pc = $s >> 7;
		if ($pc && $pc <= CP_KING) {
			my $shift = $s & 63;
			my $co = ($s >> 6) & 1;
			my $square = $self->shiftToSquare($shift);
			my $piece_char = CP_PIECE_CHARS->[$co]->[$pc];
			$output .= "$piece_char:$square:";
		} else {
			$output .= '     ';
		}
		$output .= sprintf " 0x%016x (%d)\n", $zk_pieces[$i], $zk_pieces[$i];
	}

	$output .= "\nEn-Passant Files\n";
	$output .= "================\n\n";
	foreach my $file (CP_FILE_A .. CP_FILE_H) {
		my $char = chr($file + ord('a'));
		$output .= sprintf "$char: 0x%016x (%d)\n", $zk_ep_files[$file], $zk_ep_files[$file];
	}

	$output .= "\nCastling States\n";
	$output .= "===============\n\n";
	foreach my $castling (0 .. 15) {
		my $castle = '';
		if ($castling) {
			$castle .= 'K' if $castling & 0x1;
			$castle .= 'Q' if $castling & 0x2;
			$castle .= 'k' if $castling & 0x4;
			$castle .= 'q' if $castling & 0x8;
		} else {
			$castle = '-';
		}

		$output .= sprintf "% 2u:% 4s: 0x%016x (%d)\n", $castling, $castle, $zk_castling[$castling], $zk_castling[$castling];
	}

	$output .= "\nColor\n=====\n\n";
	$output .= sprintf "1:black: 0x%016x (%d)\n", $zk_color, $zk_color;

	return $output;
}

sub insufficientMaterial {
	my ($self, $forcible) = @_;

	# All of these are sufficient to mate.
	if (cp_pos_pawns($self) | cp_pos_rooks($self) | cp_pos_queens($self)) {
		return;
	}

	# There is neither a queen nor a rook nor a pawn.
	my $bishop_bb = cp_pos_bishops $self;
	my $knight_bb = cp_pos_knights $self;
	my $not_kings = $bishop_bb | $knight_bb;
	if (!cp_bitboard_more_than_one_set $not_kings) {
		# Lone king versus lone king or a single minor piece.  Always a draw.
		return 1;
	}
	
	# We have at least two minor pieces.  The only situation, where a mate
	# is technically impossible is, when we have only same-coloured bishops,
	# no matter on which side.
	if (!$forcible && $bishop_bb && $knight_bb) {
		return; # Mate theoretically possible.
	}

	my $light_squared_bishop_bb = $bishop_bb & CP_LIGHT_MASK;
	my $dark_squared_bishop_bb = $bishop_bb & CP_DARK_MASK;

	if (!($light_squared_bishop_bb && $dark_squared_bishop_bb)) {
		# We either have no bishops or all bishops move on same-coloured
		# fields. If we have knights, a mate can be delivered.
		#
		# If there are no knights, all bishops move on the same squares. No
		# matter how many we have, this is always a draw. If there are knights,
		# a mate is maybe possible if one side has more than one knight.
		if (!$knight_bb) {
			return 1; # Only same-coloured bishops on the board.
		}

		# We have knights. If there are knights and bishops or more than one
		# knight, a mate is theoretically possible.
		if (!$forcible) {
			return if $bishop_bb || cp_bitboard_more_than_one_set $knight_bb;
		}

		# There is at least one knight. We only considered KNNvK a forcible draw.
		# Probing Syzygy endgame tables shows more constellations but this is
		# out of scope of this function.
		my $white_pieces = cp_pos_white_pieces $self;
		my $black_pieces = cp_pos_black_pieces $self;
		my $white_knight_bb = $white_pieces & $knight_bb;
		my $black_knight_bb = $black_pieces & $knight_bb;
		my $white_knight_pair = cp_bitboard_more_than_one_set($white_knight_bb);
		my $black_knight_pair = cp_bitboard_more_than_one_set($black_knight_bb);

		# If both sides have a knight pair, we do not report a draw,
		# although endgame tablebases will probably consider most of them
		# a draw.
		return 1 if $white_knight_pair && $black_knight_pair;

		if (!$bishop_bb) {
			# Only KNNvK and KNvKN are considered a draw. We can detect that
			# with a popcount of the knight bitboard.
			my $num_knights;
			cp_bitboard_popcount $knight_bb, $num_knights;

			return $num_knights <= 2;
		}
	} else {
		return if !$forcible; # Mate theoratically possible.

		# The bishops are different-coloured, and we have at least two.
		# If one side has at least two bishops, a mate can be forced.
		my $white_pieces = cp_pos_white_pieces $self;
		my $black_pieces = cp_pos_black_pieces $self;

		if (!($bishop_bb & $white_pieces) && ($bishop_bb && $black_pieces)) {
			# All bishops are on one side. A mate can probably be forced.
			return;
		}

		# Both sides have at least one bishop. We consider KBvKB a draw,
		# all other cases can be won.
		return if $knight_bb;

		# We only have bishops. If either side has more than one bishop,
		# the position is considered winnable.
		my $white_bishop_pair = cp_bitboard_more_than_one_set($white_pieces & $bishop_bb);
		my $black_bishop_pair = cp_bitboard_more_than_one_set($white_pieces & $bishop_bb);

		if ((!$white_bishop_pair) && !($black_bishop_pair)) {
			# Either side has exactly one bishop.
			return 1;
		}
	}

	# In all other cases, we cannot determine the outcome.
	return;
}

sub enPassantFileToShift {
	my ($whatever, $ep_file, $turn) = @_;

	return cp_en_passant_file_to_shift $ep_file, $turn;
}


sub inCheck {
	my ($self) = @_;

	my $turn = cp_pos_to_move($self);
	my $kings_bb = cp_pos_kings($self)
		& ($turn ? cp_pos_black_pieces($self) : cp_pos_white_pieces($self));
	my $king_shift = cp_bitboard_count_isolated_trailing_zbits($kings_bb);

	my $checkers = _cp_pos_color_attacked $self, $turn, $king_shift;

	if (wantarray) {
		my $defence_bb;

		# Additionally return king_shift and defence bitboard.
		if ($checkers) {
			# Check evasion strategy.  If in-check, the options are:
			#
			# 1. Move the king.
			# 2. Hit the piece that gives check unless multiple pieces give
			#.   check.
			# 3. Move a piece in front of the king for protection unless a
			#    knight gives check or two pieces give check simultaneously.
			#
			# That leads to 3 different levels for the evasion strategy.
			# Option 1 is always valid. Option 2 only if only one piece gives
			# check.  Option 3 if only one piece gives check and the piece is
			# a queen, bishop or rook.
			#
			# Pawn checks can be treated like knight checks because the pawn
			# always has direct contact with the king.
			#
			# For both options 2 and 3 we define a defence bitboard of valid
			# target squares.  This information is then used in the legality
			# check for non-king moves to see whether the move prevents a check.
			# There is no need to distinguish between the two cases in the
			# legality check. The difference is just the popcount of the
			# defence bitboard.
			if ($checkers & ($checkers - 1)) {
				# More than one piece giving check.  The king has to move.
				# In this case, the defence bitboard can be ignored.
				$defence_bb = 0;
			} elsif ($checkers & (cp_pos_knights($self) | (cp_pos_pawns($self)))) {
				$defence_bb = $checkers;
			} else {
				my $piece_shift = cp_bitboard_count_isolated_trailing_zbits $checkers;
				my ($attack_type, undef, $attack_ray) =
					@{$common_lines[$king_shift]->[$piece_shift]};
				if ($attack_ray) {
					$defence_bb = $attack_ray;
				} else {
					$defence_bb = $checkers;
				}
			}
		}

		return $checkers, $king_shift, $defence_bb;
	} else {
		# Old version.
		return $checkers;
	}
}

sub checkPseudoLegalMove {
	my ($self, $move, $in_check, $king_shift, $defence_bb) = @_;

	my $from = cp_move_from $move;
	my $to = cp_move_to $move;
	my $piece = cp_move_piece $move;
	my $pos_info = cp_pos_info $self;
	my $to_move = cp_pos_info_to_move($pos_info);
	my $my_pieces = $self->[CP_POS_WHITE_PIECES + $to_move];
	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$to_move];

	# A pseudo-legal move can be illegal for these reasons:
	#
	# 1. The moving piece is pinned by a sliding piece and would expose our
	#    king to check.
	# 2. The king moves into check.
	# 3. The king crosses an attacked square while castling.
	# 4. A pawn captured en passant discovers a check.
	#
	# Checks number two and three are done below, and only for king moves.
	# Check number 4 is done below for en passant moves.
	return if _cp_pos_move_pinned $self, $from, $to, $king_shift, $my_pieces, $her_pieces;

	my $ep = cp_pos_info_en_passant $pos_info;
	my $ep_shift = $ep ? cp_en_passant_file_to_shift($ep, $to_move) : 0;
	my $is_ep;
	my $to_mask = 1 << $to;

	if ($piece == CP_KING) {
		# Does the king move into check?
		return if _cp_pos_move_attacked $self, $from, $to;

		# Castling?
		if ((($from - $to) & 0x3) == 0x2) {
			# Are we checked?
			return if $in_check;

			# Is the field that the king has to cross attacked?
			return if _cp_pos_color_attacked $self, $to_move, ($from + $to) >> 1;
		}
	} elsif ($in_check) {
		# We are in check but the piece that moves is not a king. We must
		# either capture the piece giving check or block it.
		if (!($defence_bb & $to_mask)) {
			# Exception: En passant capture if the capture pawn is the one
			# that gives check.
			if (!($piece == CP_PAWN && $to == $ep_shift
			      && ($ep_pawn_masks[$ep_shift] & $in_check))) {
				return;
			}
		}
	}

	if ($piece == CP_PAWN) {
		if ($ep_shift && $to == $ep_shift) {
			$is_ep = 1;

			# Removing the pawn may discover a check.
			my $move_mask = (1 << $from) | $to_mask;
			my $captured_mask = $ep_pawn_masks[$ep_shift];

			my $occupancy = (cp_pos_white_pieces($self) | cp_pos_black_pieces($self))
					& ((~$move_mask) ^ $captured_mask);
			if (cp_mm_bmagic($king_shift, $occupancy) & $her_pieces
				& (cp_pos_bishops($self) | cp_pos_queens($self))) {
				return;
			} elsif (cp_mm_rmagic($king_shift, $occupancy) & $her_pieces
				& (cp_pos_rooks($self) | cp_pos_queens($self))) {
				return;
			}
		}
	}

	my $capture_mask = $to_mask & $her_pieces;
	my $captured = CP_NO_PIECE;
	if ($capture_mask) {
		if ($capture_mask & cp_pos_pawns $self) {
			$captured = CP_PAWN;
		} elsif ($capture_mask & cp_pos_knights $self) {
			$captured = CP_KNIGHT;
		} elsif ($capture_mask & cp_pos_bishops $self) {
			$captured = CP_BISHOP;
		} elsif ($capture_mask & cp_pos_rooks $self) {
			$captured = CP_ROOK;
		} else {
			$captured = CP_QUEEN;
		}
	} elsif ($is_ep) {
		cp_move_set_en_passant $move, 1;
		$captured = CP_PAWN;
	}

	cp_move_set_captured $move, $captured;
	cp_move_set_color $move, $to_move;

	return $move;
}

sub legalMoves {
	my ($self) = @_;

	# Normal subroutine invocations are faster than method calls.
	my @check_state = inCheck($self);

	my @legal;
	foreach my $move (pseudoLegalMoves($self)) {
		$move = checkPseudoLegalMove($self, $move, @check_state) or next;
		push @legal, $move;
	}

	return @legal;
}

sub halfmoveClock {
	my ($self) = @_;

	return cp_pos_halfmove_clock($self);
}

# Do not remove this line!
# __END_MACROS__

my @export_accessors = qw(
	CP_POS_WHITE_PIECES CP_POS_BLACK_PIECES
	CP_POS_KINGS CP_POS_QUEENS
	CP_POS_ROOKS CP_POS_BISHOPS CP_POS_KNIGHTS CP_POS_PAWNS
	CP_POS_HALFMOVE_CLOCK CP_POS_HALFMOVES
	CP_POS_INFO
);

my @export_board = qw(
	CP_FILE_A CP_FILE_B CP_FILE_C CP_FILE_D
	CP_FILE_E CP_FILE_F CP_FILE_G CP_FILE_H
	CP_RANK_1 CP_RANK_2 CP_RANK_3 CP_RANK_4
	CP_RANK_5 CP_RANK_6 CP_RANK_7 CP_RANK_8
	CP_A1 CP_A2 CP_A3 CP_A4 CP_A5 CP_A6 CP_A7 CP_A8
	CP_B1 CP_B2 CP_B3 CP_B4 CP_B5 CP_B6 CP_B7 CP_B8
	CP_C1 CP_C2 CP_C3 CP_C4 CP_C5 CP_C6 CP_C7 CP_C8
	CP_D1 CP_D2 CP_D3 CP_D4 CP_D5 CP_D6 CP_D7 CP_D8
	CP_E1 CP_E2 CP_E3 CP_E4 CP_E5 CP_E6 CP_E7 CP_E8
	CP_F1 CP_F2 CP_F3 CP_F4 CP_F5 CP_F6 CP_F7 CP_F8
	CP_G1 CP_G2 CP_G3 CP_G4 CP_G5 CP_G6 CP_G7 CP_G8
	CP_H1 CP_H2 CP_H3 CP_H4 CP_H5 CP_H6 CP_H7 CP_H8
	CP_A_MASK CP_B_MASK CP_C_MASK CP_D_MASK
	CP_E_MASK CP_F_MASK CP_G_MASK CP_H_MASK
	CP_1_MASK CP_2_MASK CP_3_MASK CP_4_MASK
	CP_5_MASK CP_6_MASK CP_7_MASK CP_8_MASK
	CP_WHITE_MASK CP_BLACK_MASK CP_LIGHT_MASK CP_DARK_MASK
);

my @export_pieces = qw(
	CP_WHITE CP_BLACK
	CP_NO_PIECE CP_PAWN CP_KNIGHT CP_BISHOP CP_ROOK CP_QUEEN CP_KING
	CP_PAWN_VALUE CP_KNIGHT_VALUE CP_BISHOP_VALUE CP_ROOK_VALUE CP_QUEEN_VALUE
	CP_PIECE_CHARS
);

my @export_magicmoves = qw(
	CP_MAGICMOVES_B_MAGICS
	CP_MAGICMOVES_R_MAGICS
	CP_MAGICMOVES_B_MASK
	CP_MAGICMOVES_R_MASK
	CP_MAGICMOVESBDB
	CP_MAGICMOVESRDB
);

my @export_game = qw(
	CP_GAME_OVER
	CP_GAME_WHITE_WINS
	CP_GAME_BLACK_WINS
	CP_GAME_STALEMATE
	CP_GAME_FIFTY_MOVES
	CP_GAME_INSUFFICIENT_MATERIAL
);

my @export_aux = qw(CP_INT_SIZE CP_CHAR_BIT CP_RANDOM_SEED);

our @EXPORT_OK = (@export_pieces, @export_board, @export_accessors,
		@export_magicmoves, @export_game, @export_aux);

our %EXPORT_TAGS = (
	accessors => [@export_accessors],
	pieces => [@export_pieces],
	board => [@export_board],
	magicmoves => [@export_magicmoves],
	aux => [@export_aux],
	# game => [@export_game],
	all => [@EXPORT_OK],
);

# Bit twiddling stuff.
use constant CP_INT_SIZE => $Config{ivsize};
use constant CP_CHAR_BIT => 8;

# Diagonals parallel to a1-h8.
use constant CP_A1A1_MASK => 0x0000000000000001;
use constant CP_B1A2_MASK => 0x0000000000000102;
use constant CP_C1A3_MASK => 0x0000000000010204;
use constant CP_D1A4_MASK => 0x0000000001020408;
use constant CP_E1A5_MASK => 0x0000000102040810;
use constant CP_F1A6_MASK => 0x0000010204081020;
use constant CP_G1A7_MASK => 0x0001020408102040;
use constant CP_H1A8_MASK => 0x0102040810204080;
use constant CP_H2B8_MASK => 0x0204081020408000;
use constant CP_H3C8_MASK => 0x0408102040800000;
use constant CP_H4D8_MASK => 0x0810204080000000;
use constant CP_H5E8_MASK => 0x1020408000000000;
use constant CP_H6F8_MASK => 0x2040800000000000;
use constant CP_H7G8_MASK => 0x4080000000000000;
use constant CP_H8H8_MASK => 0x8000000000000000;

# Diagonals parallel to h1-a8
use constant CP_H1H1_MASK => 0x0000000000000080;
use constant CP_H2G1_MASK => 0x0000000000008040;
use constant CP_H3F1_MASK => 0x0000000000804020;
use constant CP_H4E1_MASK => 0x0000000080402010;
use constant CP_H5D1_MASK => 0x0000008040201008;
use constant CP_H6C1_MASK => 0x0000804020100804;
use constant CP_H7B1_MASK => 0x0080402010080402;
use constant CP_H8A1_MASK => 0x8040201008040201;
use constant CP_G8A2_MASK => 0x4020100804020100;
use constant CP_F8A3_MASK => 0x2010080402010000;
use constant CP_E8A4_MASK => 0x1008040201000000;
use constant CP_D8A5_MASK => 0x0804020100000000;
use constant CP_C8A6_MASK => 0x0402010000000000;
use constant CP_B8A7_MASK => 0x0201000000000000;
use constant CP_A8A8_MASK => 0x0100000000000000;

# Diagonals parallel to a1-h8, the other way round.
use constant CP_A2B1_MASK => 0x0000000000000102;
use constant CP_A3C1_MASK => 0x0000000000010204;
use constant CP_A4D1_MASK => 0x0000000001020408;
use constant CP_A5E1_MASK => 0x0000000102040810;
use constant CP_A6F1_MASK => 0x0000010204081020;
use constant CP_A7G1_MASK => 0x0001020408102040;
use constant CP_A8H1_MASK => 0x0102040810204080;
use constant CP_B8H2_MASK => 0x0204081020408000;
use constant CP_C8H3_MASK => 0x0408102040800000;
use constant CP_D8H4_MASK => 0x0810204080000000;
use constant CP_E8H5_MASK => 0x1020408000000000;
use constant CP_F8H6_MASK => 0x2040800000000000;
use constant CP_G8H7_MASK => 0x4080000000000000;

# Diagonals parallel to h1-a8, the other way round.
use constant CP_G1H2_MASK => 0x0000000000008040;
use constant CP_F1H3_MASK => 0x0000000000804020;
use constant CP_E1H4_MASK => 0x0000000080402010;
use constant CP_D1H5_MASK => 0x0000008040201008;
use constant CP_C1H6_MASK => 0x0000804020100804;
use constant CP_B1H7_MASK => 0x0080402010080402;
use constant CP_A1H8_MASK => 0x8040201008040201;
use constant CP_A2G8_MASK => 0x4020100804020100;
use constant CP_A3F8_MASK => 0x2010080402010000;
use constant CP_A4E8_MASK => 0x1008040201000000;
use constant CP_A5D8_MASK => 0x0804020100000000;
use constant CP_A6C8_MASK => 0x0402010000000000;
use constant CP_A7B8_MASK => 0x0201000000000000;

@magicmoves_r_magics = (
	0x0080001020400080, 0x0040001000200040, 0x0080081000200080, 0x0080040800100080,
	0x0080020400080080, 0x0080010200040080, 0x0080008001000200, 0x0080002040800100,
	0x0000800020400080, 0x0000400020005000, 0x0000801000200080, 0x0000800800100080,
	0x0000800400080080, 0x0000800200040080, 0x0000800100020080, 0x0000800040800100,
	0x0000208000400080, 0x0000404000201000, 0x0000808010002000, 0x0000808008001000,
	0x0000808004000800, 0x0000808002000400, 0x0000010100020004, 0x0000020000408104,
	0x0000208080004000, 0x0000200040005000, 0x0000100080200080, 0x0000080080100080,
	0x0000040080080080, 0x0000020080040080, 0x0000010080800200, 0x0000800080004100,
	0x0000204000800080, 0x0000200040401000, 0x0000100080802000, 0x0000080080801000,
	0x0000040080800800, 0x0000020080800400, 0x0000020001010004, 0x0000800040800100,
	0x0000204000808000, 0x0000200040008080, 0x0000100020008080, 0x0000080010008080,
	0x0000040008008080, 0x0000020004008080, 0x0000010002008080, 0x0000004081020004,
	0x0000204000800080, 0x0000200040008080, 0x0000100020008080, 0x0000080010008080,
	0x0000040008008080, 0x0000020004008080, 0x0000800100020080, 0x0000800041000080,
	0x00FFFCDDFCED714A, 0x007FFCDDFCED714A, 0x003FFFCDFFD88096, 0x0000040810002101,
	0x0001000204080011, 0x0001000204000801, 0x0001000082000401, 0x0001FFFAABFAD1A2
);

@magicmoves_r_mask = (
	0x000101010101017E, 0x000202020202027C, 0x000404040404047A, 0x0008080808080876,
	0x001010101010106E, 0x002020202020205E, 0x004040404040403E, 0x008080808080807E,
	0x0001010101017E00, 0x0002020202027C00, 0x0004040404047A00, 0x0008080808087600,
	0x0010101010106E00, 0x0020202020205E00, 0x0040404040403E00, 0x0080808080807E00,
	0x00010101017E0100, 0x00020202027C0200, 0x00040404047A0400, 0x0008080808760800,
	0x00101010106E1000, 0x00202020205E2000, 0x00404040403E4000, 0x00808080807E8000,
	0x000101017E010100, 0x000202027C020200, 0x000404047A040400, 0x0008080876080800,
	0x001010106E101000, 0x002020205E202000, 0x004040403E404000, 0x008080807E808000,
	0x0001017E01010100, 0x0002027C02020200, 0x0004047A04040400, 0x0008087608080800,
	0x0010106E10101000, 0x0020205E20202000, 0x0040403E40404000, 0x0080807E80808000,
	0x00017E0101010100, 0x00027C0202020200, 0x00047A0404040400, 0x0008760808080800,
	0x00106E1010101000, 0x00205E2020202000, 0x00403E4040404000, 0x00807E8080808000,
	0x007E010101010100, 0x007C020202020200, 0x007A040404040400, 0x0076080808080800,
	0x006E101010101000, 0x005E202020202000, 0x003E404040404000, 0x007E808080808000,
	0x7E01010101010100, 0x7C02020202020200, 0x7A04040404040400, 0x7608080808080800,
	0x6E10101010101000, 0x5E20202020202000, 0x3E40404040404000, 0x7E80808080808000
);

@magicmoves_b_magics = (
	0x0002020202020200, 0x0002020202020000, 0x0004010202000000, 0x0004040080000000,
	0x0001104000000000, 0x0000821040000000, 0x0000410410400000, 0x0000104104104000,
	0x0000040404040400, 0x0000020202020200, 0x0000040102020000, 0x0000040400800000,
	0x0000011040000000, 0x0000008210400000, 0x0000004104104000, 0x0000002082082000,
	0x0004000808080800, 0x0002000404040400, 0x0001000202020200, 0x0000800802004000,
	0x0000800400A00000, 0x0000200100884000, 0x0000400082082000, 0x0000200041041000,
	0x0002080010101000, 0x0001040008080800, 0x0000208004010400, 0x0000404004010200,
	0x0000840000802000, 0x0000404002011000, 0x0000808001041000, 0x0000404000820800,
	0x0001041000202000, 0x0000820800101000, 0x0000104400080800, 0x0000020080080080,
	0x0000404040040100, 0x0000808100020100, 0x0001010100020800, 0x0000808080010400,
	0x0000820820004000, 0x0000410410002000, 0x0000082088001000, 0x0000002011000800,
	0x0000080100400400, 0x0001010101000200, 0x0002020202000400, 0x0001010101000200,
	0x0000410410400000, 0x0000208208200000, 0x0000002084100000, 0x0000000020880000,
	0x0000001002020000, 0x0000040408020000, 0x0004040404040000, 0x0002020202020000,
	0x0000104104104000, 0x0000002082082000, 0x0000000020841000, 0x0000000000208800,
	0x0000000010020200, 0x0000000404080200, 0x0000040404040400, 0x0002020202020200
);

@magicmoves_b_mask = (
	0x0040201008040200, 0x0000402010080400, 0x0000004020100A00, 0x0000000040221400,
	0x0000000002442800, 0x0000000204085000, 0x0000020408102000, 0x0002040810204000,
	0x0020100804020000, 0x0040201008040000, 0x00004020100A0000, 0x0000004022140000,
	0x0000000244280000, 0x0000020408500000, 0x0002040810200000, 0x0004081020400000,
	0x0010080402000200, 0x0020100804000400, 0x004020100A000A00, 0x0000402214001400,
	0x0000024428002800, 0x0002040850005000, 0x0004081020002000, 0x0008102040004000,
	0x0008040200020400, 0x0010080400040800, 0x0020100A000A1000, 0x0040221400142200,
	0x0002442800284400, 0x0004085000500800, 0x0008102000201000, 0x0010204000402000,
	0x0004020002040800, 0x0008040004081000, 0x00100A000A102000, 0x0022140014224000,
	0x0044280028440200, 0x0008500050080400, 0x0010200020100800, 0x0020400040201000,
	0x0002000204081000, 0x0004000408102000, 0x000A000A10204000, 0x0014001422400000,
	0x0028002844020000, 0x0050005008040200, 0x0020002010080400, 0x0040004020100800,
	0x0000020408102000, 0x0000040810204000, 0x00000A1020400000, 0x0000142240000000,
	0x0000284402000000, 0x0000500804020000, 0x0000201008040200, 0x0000402010080400,
	0x0002040810204000, 0x0004081020400000, 0x000A102040000000, 0x0014224000000000,
	0x0028440200000000, 0x0050080402000000, 0x0020100804020000, 0x0040201008040200
);

sub copy {
	my ($self) = @_;

	bless [@$self], ref $self;
}

sub whitePieces {
	shift->[CP_POS_WHITE_PIECES];
}

sub blackPieces {
	shift->[CP_POS_BLACK_PIECES];
}

sub kings {
	shift->[CP_POS_KINGS];
}

sub queens {
	shift->[CP_POS_QUEENS];
}

sub rooks {
	shift->[CP_POS_ROOKS];
}

sub bishops {
	shift->[CP_POS_BISHOPS];
}

sub knights {
	shift->[CP_POS_KNIGHTS];
}

sub pawns {
	shift->[CP_POS_PAWNS];
}

sub occupied {
	my ($self) = @_;

	return $self->[CP_POS_WHITE_PIECES] | $self->[CP_POS_BLACK_PIECES];
}

sub vacant {
	my ($self) = @_;

	return ~($self->[CP_POS_WHITE_PIECES] | $self->[CP_POS_BLACK_PIECES]);
}

sub halfmoves {
	shift->[CP_POS_HALFMOVES];
}

sub info {
	shift->[CP_POS_INFO];
}

sub toFEN {
	my ($self) = @_;

	my $w_pieces = $self->[CP_POS_WHITE_PIECES];
	my $b_pieces = $self->[CP_POS_BLACK_PIECES];
	my $pieces = $w_pieces | $b_pieces;
	my $pawns = $self->[CP_POS_PAWNS];
	my $bishops = $self->[CP_POS_BISHOPS];
	my $knights = $self->[CP_POS_KNIGHTS];
	my $rooks = $self->[CP_POS_ROOKS];
	my $queens = $self->[CP_POS_QUEENS];

	my $fen = '';

	for (my $rank = CP_RANK_8; $rank >= CP_RANK_1; --$rank) {
		my $empty = 0;
		for (my $file = CP_FILE_A; $file <= CP_FILE_H; ++$file) {
			my $shift = $self->coordinatesToShift($file, $rank);
			my $mask = 1 << $shift;

			if ($mask & $pieces) {
				if ($empty) {
					$fen .= $empty;
					$empty = 0;
				}

				if ($mask & $w_pieces) {
					if ($mask & $pawns) {
						$fen .= 'P';
					} elsif ($mask & $knights) {
						$fen .= 'N';
					} elsif ($mask & $bishops) {
						$fen .= 'B';
					} elsif ($mask & $rooks) {
						$fen .= 'R';
					} elsif ($mask & $queens) {
						$fen .= 'Q';
					} else {
						$fen .= 'K';
					}
				} elsif ($mask & $b_pieces) {
					if ($mask & $pawns) {
						$fen .= 'p';
					} elsif ($mask & $knights) {
						$fen .= 'n';
					} elsif ($mask & $bishops) {
						$fen .= 'b';
					} elsif ($mask & $rooks) {
						$fen .= 'r';
					} elsif ($mask & $queens) {
						$fen .= 'q';
					} else {
						$fen .= 'k';
					}
				}
			} else {
				++$empty;
			}

			if ($file == CP_FILE_H) {
				if ($empty) {
					$fen .= $empty;
					$empty = 0;
				}
				if ($rank != CP_RANK_1) {
					$fen .= '/';
				}
			}
		}
	}

	$fen .= ($self->toMove == CP_WHITE) ? ' w ' : ' b ';

	my $castling = $self->castlingRights;

	if ($castling) {
		my $castle = '';
		$castle .= 'K' if $castling & 0x1;
		$castle .= 'Q' if $castling & 0x2;
		$castle .= 'k' if $castling & 0x4;
		$castle .= 'q' if $castling & 0x8;
		$fen .= "$castle ";
	} else {
		$fen .= '- ';
	}

	my $ep = $self->enPassant;
	if ($ep) {
		my $ep_shift = $self->enPassantFileToShift($ep, $self->toMove);
		my $square = $self->shiftToSquare($ep_shift);
		$fen .= $square;
	} else {
		$fen .= '-';
	}

	$fen .= sprintf ' %u %u', $self->halfmoveClock,
			1 + ($self->[CP_POS_HALFMOVES] >> 1);

	return $fen;
}

sub board {
	my ($self) = @_;

	my $w_pieces = $self->[CP_POS_WHITE_PIECES];
	my $b_pieces = $self->[CP_POS_BLACK_PIECES];
	my $pieces = $w_pieces | $b_pieces;
	my $pawns = $self->[CP_POS_PAWNS];
	my $bishops = $self->[CP_POS_BISHOPS];
	my $knights = $self->[CP_POS_KNIGHTS];
	my $rooks = $self->[CP_POS_ROOKS];
	my $queens = $self->[CP_POS_QUEENS];

	my $ep_shift = $self->enPassantShift;
	my $board = "  a b c d e f g h\n";
	if ($self->blackQueenSideCastlingRight) {
		$board .= " +-+-<-<-<-";
	} else {
		$board .= " +-+-+-+-+-";
	}
	if ($self->blackKingSideCastlingRight) {
		$board .= ">->-+-+\n";
	} else {
		$board .= "+-+-+-+\n";
	}

	for (my $rank = CP_RANK_8; $rank >= CP_RANK_1; --$rank) {
		$board .= ($rank + 1) . '|';
		for (my $file = CP_FILE_A; $file <= CP_FILE_H; ++$file) {
			my $shift = $self->coordinatesToShift($file, $rank);
			my $mask = 1 << $shift;

			$board .= ' ' if $file != CP_FILE_A;
			if ($mask & $pieces) {
				if ($mask & $w_pieces) {
					if ($mask & $pawns) {
						$board .= 'P';
					} elsif ($mask & $knights) {
						$board .= 'N';
					} elsif ($mask & $bishops) {
						$board .= 'B';
					} elsif ($mask & $rooks) {
						$board .= 'R';
					} elsif ($mask & $queens) {
						$board .= 'Q';
					} else {
						$board .= 'K';
					}
				} elsif ($mask & $b_pieces) {
					if ($mask & $pawns) {
						$board .= 'p';
					} elsif ($mask & $knights) {
						$board .= 'n';
					} elsif ($mask & $bishops) {
						$board .= 'b';
					} elsif ($mask & $rooks) {
						$board .= 'r';
					} elsif ($mask & $queens) {
						$board .= 'q';
					} else {
						$board .= 'k';
					}
				}
			} elsif ($ep_shift && $shift == $ep_shift) {
				if ($self->toMove == CP_WHITE) {
					$board .= 'v';
				} else {
					$board .= '^';
				}
			} else {
				$board .= '.';
			}

			if ($file == CP_FILE_H) {
			}
		}
		$board .= '|' . ($rank + 1) . "\n";
	}

	if ($self->whiteQueenSideCastlingRight) {
		$board .= " +-+-<-<-<-";
	} else {
		$board .= " +-+-+-+-+-";
	}
	if ($self->whiteKingSideCastlingRight) {
		$board .= ">->-+-+\n";
	} else {
		$board .= "+-+-+-+\n";
	}

	return $board;
}

sub dumpBitboard {
	my (undef, $bitboard) = @_;

	my $output = "  a b c d e f g h\n";
	foreach my $rank (reverse(0 .. 7)) {
		$output .= $rank + 1;
		foreach my $file (0 .. 7) {
			my $shift = ($rank << 3) + $file;
			if ($bitboard & 1 << $shift) {
				$output .= ' x';
			} else {
				$output .= ' .';
			}
		}
		$output .= ' ' . ($rank + 1) . "\n";
	}
	$output .= "  a b c d e f g h\n";

	return $output;
}

sub SAN {
	my ($self, $move, $use_pseudo_legal_moves) = @_;

	my ($from, $to, $promote, $piece) = (
		$self->moveFrom($move),
		$self->moveTo($move),
		$self->movePromote($move),
		$self->movePiece($move),
	);

	if ($piece == CP_KING && ((($from - $to) & 0x3) == 0x2)) {
		my $to_mask = 1 << $to;
		if ($to_mask & CP_G_MASK) {
			return 'O-O';
		} else {
			return 'O-O-O';
		}
	}

	# Avoid extra hassle for queen moves.
	my @pieces = ('', '', 'N', 'B', 'R', 'Q', 'K');

	my $san = $pieces[$piece];

	my $from_board = $self->[CP_POS_WHITE_PIECES + $self->toMove]
		& $self->[CP_POS_BLACK_PIECES + $piece];

	# Or use legalMoves?
	my @legal_moves = $self->legalMoves or return;
	my @cmoves = $use_pseudo_legal_moves
		? $self->pseudoLegalMoves : @legal_moves;
	return if !@cmoves;

	my (%files, %ranks);
	my $candidates = 0;
	# When we iterate over the moves make sure that we do not count moves that
	# just differ in the promotion piece, four times.  We do that by just
	# stripping off the promotion piece and making the array unique.
	my %cmoves = map { $_ => 1 }
			map { $self->moveSetPromote($_, CP_NO_PIECE) }
			@cmoves;
	foreach my $cmove (keys %cmoves) {
		my ($cfrom, $cto, $cpiece) = ($self->moveFrom($cmove), $self->moveTo($cmove), $self->movePiece($cmove));
		next if $cto != $to;
		next if $cpiece != $piece;

		++$candidates;
		my ($ffile, $frank) = $self->shiftToCoordinates($cfrom);
		++$files{$ffile};
		++$ranks{$frank};
	}

	my $to_mask = 1 << $to;
	my $to_move = $self->toMove;
	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$to_move];
	my $ep = $self->enPassant;
	my $ep_shift = $ep ? $self->enPassantFileToShift($ep, $to_move) : 0;
	my @files = ('a' .. 'h');
	my @ranks = ('1' .. '8');
	my ($from_file, $from_rank) = $self->shiftToCoordinates($from);

	if ($candidates > 1) {
		my $numfiles = keys %files;
		my $numranks = keys %ranks;

		if ($numfiles == $candidates) {
			$san .= $files[$from_file];
		} elsif ($numranks == $candidates) {
			$san .= $ranks[$from_rank];
		} else {
			$san .= "$files[$from_file]$ranks[$from_rank]";
		}
	}

	if (($to_mask & $her_pieces)
	    || ($ep_shift && $piece == CP_PAWN && $to == $ep_shift)) {
		# Capture.  For pawn captures we always add the file unless it was
		# already added.
		if ($piece == CP_PAWN && !length $san) {
			$san .= $files[$from_file];
		}
		$san .= 'x';
	}

	$san .= $self->shiftToSquare($to);

	my $promote = $self->movePromote($move);
	if ($promote) {
		$san .= "=$pieces[$promote]";
	}

	my $copy = $self->copy;
	if ($copy->doMove($move) && $copy->inCheck) {
		my @moves = $copy->legalMoves;
		if (!@moves) {
			$san .= '#';
		} else {
			$san .= '+';
		}
	}

	return $san;
}

sub equals {
	my ($self, $other) = @_;

	return if @$self != @$other;

	for (my $i = 0; $i < @$self; ++$i) {
		return if $self->[$i] != $other->[$i];
	}

	return $self;
}

my %rng_seen;
sub RNG {
	while (1) {
		$cp_random ^= ($cp_random << 21);
		$cp_random ^= (($cp_random >> 35) & 0x1fff_ffff);
		$cp_random ^= ($cp_random << 4);

		last if !$rng_seen{$cp_random}++;
	}

	return $cp_random;
}

sub __parseSAN {
	my ($self, $move) = @_;

	# First clean-up but in multiple steps.
	my $san = $move;

	# First delete whitespace and dots.
	$san =~ s/[ \011-\015\.]//g;

	# So that we can strip-off s possible en-passant notation.
	$san =~ s/ep//gi;

	# And now other noise.
	$san =~ s/[^a-h0-8pnbrqko]//gi;

	my $pattern;

	my $to_move = $self->toMove;
	if ($san =~ /^[0oO][0oO]([0oO])?$/) {
		my $queen_side = $1;

		if ($to_move == CP_WHITE) {
			if ($queen_side) {
				$pattern = 'Ke1c1';
			} else {
				$pattern = 'Ke1g1';
			}
		} else {
			if ($queen_side) {
				$pattern = 'Ke8c8';
			} else {
				$pattern = 'Ke8g8';
			}
		}
	} else {
		my $piece = '.',
		my $from_file = '.';
		my $to_file = '.';
		my $from_rank = '.';
		my $to_rank = '.',
		my $promote = '';

		# Before we convert to lowercase, we try to extract the moving piece
		# which must always be uppercase.
		if ($san =~ s/^([PNBRQK])//) {
			$piece = $1;
		}

		my @san = split //, lc $san;

		my %pieces = map { $_ => 1 } qw(p n b r q k);

		# Promotion?
		if (exists $pieces{$san[-1]}) {
			$promote = $san[-1];
			pop @san;
		}

		# Target rank?
		if (@san && $san[-1] >= '1' && $san[-1] <= '8') {
			$to_rank = $san[-1];
			pop @san;
		}

		# Target file?
		if (@san && $san[-1] >= 'a' && $san[-1] <= 'h') {
			$to_file = $san[-1];
			pop @san;
		}

		# From rank?
		if (@san && $san[-1] >= '1' && $san[-1] <= '8') {
			$from_rank = $san[-1];
			pop @san;
		}

		# From file?
		if (@san && $san[-1] >= 'a' && $san[-1] <= 'h') {
			$from_file = $san[-1];
			pop @san;
		}

		# Leading garbage?
		if (@san) {
			require Carp;
			Carp::croak(__"Illegal SAN string: leading garbage found!\n");
		}

		$pattern = join '', $piece, 
				$from_file, $from_rank, $to_file, $to_rank, $promote;
	}

	# Get the legal moves.
	my @legal = $self->movesCoordinateNotation($self->legalMoves);

	# Prefix every move with the piece that moves.
	my @pieces = qw(X P N B R Q K);
	foreach my $move (@legal) {
		my $from_square = substr $move, 0, 2;
		my $mover = $self->pieceAtSquare($from_square);
		$move = $pieces[$mover] . $move;
	}

	my @candidates;
	@candidates = grep { /^$pattern$/ } @legal;

	# We must find exactly one candidate.  If we have 0 matches, the move
	# could not be parsed.  If we have more than 1 match, the move was
	# ambiguous.
	if (@candidates != 1 && $move !~ /^[PNBRQK]/) {
		# If no piece was explicitely specified, try again with a pawn.
		$pattern =~ s/^./P/;
		@candidates = grep { /^$pattern$/ } @legal;
	}

	if (!@candidates) {
		require Carp;
		Carp::croak(__"Illegal SAN string: illegal move.\n");
	} elsif (@candidates > 1) {
		require Carp;
		Carp::croak(__"Illegal SAN string: move is ambiguous.\n");
	}

	$move = $candidates[0];
	if ($move !~ /^[PNBRQK]([a-h][1-8])([a-h][1-8])([qrbn])?$/) {
		require Carp;
		Carp::croak(__"Illegal SAN string: syntax error.\n");
	}

	return $self->__parseUCIMove($1, $2, $3);
}

sub perftByUndo {
	my ($self, $depth) = @_;

	my $nodes = 0;
	my @moves = $self->legalMoves;
	foreach my $move (@moves) {
		my $undo_info = $self->move($move);

		if ($depth > 1) {
			$nodes += $self->perftByUndo($depth - 1);
		} else {
			++$nodes;
		}

		$self->unmove($undo_info);
	}

	return $nodes;
}

sub perftByCopy {
	my ($class, $pos, $depth) = @_;

	my $nodes = 0;
	my @moves = $pos->legalMoves;
	foreach my $move (@moves) {
		my $copy = bless [@$pos], 'Chess::Plisco';
		$copy->move($move);

		if ($depth > 1) {
			$nodes += $class->perftByCopy($copy, $depth - 1);
		} else {
			++$nodes;
		}
	}

	return $nodes;
}

sub perftByUndoWithOutput {
	my ($self, $depth, $fh) = @_;

	return if $depth <= 0;

	require Time::HiRes;
	my $started = [Time::HiRes::gettimeofday()];

	my $nodes = 0;

	my @moves = $self->legalMoves;
	foreach my $move (@moves) {
		my $undo_info = $self->move($move);

		my $movestr = $self->moveCoordinateNotation($move);

		$fh->print("$movestr: ");

		my $subnodes;

		if ($depth > 1) {
			$subnodes = $self->perftByUndo($depth - 1);
		} else {
			$subnodes = 1;
		}

		$nodes += $subnodes;

		$fh->print("$subnodes\n");

		$self->unmove($undo_info);
	}

	no integer;

	my $elapsed = Time::HiRes::tv_interval($started, [Time::HiRes::gettimeofday()]);

	my $nps = '+INF';
	if ($elapsed) {
		$nps = int (0.5 + $nodes / $elapsed);
	}
	$fh->print("info nodes: $nodes ($elapsed s, nps: $nps)\n");

	return $nodes;
}

sub perftByCopyWithOutput {
	my ($self, $depth, $fh) = @_;

	return if $depth <= 0;

	require Time::HiRes;
	my $started = [Time::HiRes::gettimeofday()];

	my $nodes = 0;

	my @moves = $self->legalMoves;
	foreach my $move (@moves) {
		my $copy = bless [@$self], 'Chess::Plisco';
		$copy->move($move);

		my $movestr = $copy->moveCoordinateNotation($move);

		$fh->print("$movestr: ");

		my $subnodes;

		if ($depth > 1) {
			$subnodes = $self->perftByCopy($copy, $depth - 1);
		} else {
			$subnodes = 1;
		}

		$nodes += $subnodes;

		$fh->print("$subnodes\n");
	}

	no integer;

	my $elapsed = Time::HiRes::tv_interval($started, [Time::HiRes::gettimeofday()]);

	my $nps = '+INF';
	if ($elapsed) {
		$nps = int (0.5 + $nodes / $elapsed);
	}
	$fh->print("info nodes: $nodes ($elapsed s, nps: $nps)\n");

	return $nodes;
}

sub coordinatesToShift {
	my (undef, $file, $rank) = @_;

	return ($rank << 3) + $file;
}

sub coordinatesToSquare {
	my (undef, $file, $rank) = @_;

	return chr(97 + $file) . (1 + $rank);
}

sub shiftToCoordinates {
	my (undef, $shift) = @_;

	my $file = $shift & 0x7;
	my $rank = $shift >> 3;

	return $file, $rank;
}

sub squareToCoordinates {
	my (undef, $square) = @_;

	return ord($square) - 97, -1 + substr $square, 1;
}

sub shiftToSquare {
	my (undef, $shift) = @_;

	my $rank = 1 + ($shift >> 3);
	my $file = $shift & 0x7;

	return sprintf '%c%u', $file + ord 'a', $rank;
}

sub squareToShift {
	my ($whatever, $square) = @_;

	if ($square !~ /^([a-h])([1-8])$/) {
		die __x("Illegal square '{square}'.\n", square => $square);
	}

	my $file = ord($1) - ord('a');
	my $rank = $2 - 1;

	return $whatever->coordinatesToShift($file, $rank);
}

sub consistent {
	my ($self) = @_;

	my $consistent = 1;

	my $w_pieces = $self->[CP_POS_WHITE_PIECES];
	my $b_pieces = $self->[CP_POS_BLACK_PIECES];

	if ($w_pieces & $b_pieces) {
		warn "White and black pieces overlap.\n";
		undef $consistent;
	}

	my $occupied = $w_pieces | $b_pieces;
	my $empty = ~$occupied;	

	my $pawns = $self->[CP_POS_PAWNS];
	my $knights = $self->[CP_POS_KNIGHTS];
	my $bishops = $self->[CP_POS_BISHOPS];
	my $rooks = $self->[CP_POS_ROOKS];
	my $queens = $self->[CP_POS_QUEENS];
	my $kings = $self->[CP_POS_KINGS];

	my $occupied_by_pieces = $pawns | $knights | $bishops | $rooks | $queens
		| $kings;
	if ($occupied_by_pieces & $empty) {
		if ($pawns & $empty) {
			warn "Orphaned pawn(s) (neither black nor white).\n";
			undef $consistent;
		}
		if ($knights & $empty) {
			warn "Orphaned knight(s) (neither black nor white).\n";
			undef $consistent;
		}
		if ($bishops & $empty) {
			warn "Orphaned bishop(s) (neither black nor white).\n";
			undef $consistent;
		}
		if ($rooks & $empty) {
			warn "Orphaned rooks(s) (neither black nor white).\n";
			undef $consistent;
		}
		if ($queens & $empty) {
			warn "Orphaned queens(s) (neither black nor white).\n";
			undef $consistent;
		}
		if ($kings & $empty) {
			warn "Orphaned king(s) (neither black nor white).\n";
			undef $consistent;
		}
	}

	my $not_occupied_by_pieces = ~$occupied_by_pieces;
	if ($not_occupied_by_pieces & $b_pieces) {
		warn "Square occupied by black without a piece.\n";
		undef $consistent;
	} elsif ($not_occupied_by_pieces & $w_pieces) {
		warn "Square occupied by white without a piece.\n";
		undef $consistent;
	}

	if ($pawns & $knights) {
		warn "Pawns and knights overlap.\n";
		undef $consistent;
	}
	if ($pawns & $bishops) {
		warn "Pawns and bishops overlap.\n";
		undef $consistent;
	}
	if ($pawns & $rooks) {
		warn "Pawns and rooks overlap.\n";
		undef $consistent;
	}
	if ($pawns & $queens) {
		warn "Pawns and queens overlap.\n";
		undef $consistent;
	}
	if ($pawns & $kings) {
		warn "Pawns and kings overlap.\n";
		undef $consistent;
	}
	if ($knights & $bishops) {
		warn "Knights and bishops overlap.\n";
		undef $consistent;
	}
	if ($knights & $rooks) {
		warn "Knights and rooks overlap.\n";
		undef $consistent;
	}
	if ($knights & $queens) {
		warn "Knights and queens overlap.\n";
		undef $consistent;
	}
	if ($knights & $kings) {
		warn "Knights and kings overlap.\n";
		undef $consistent;
	}
	if ($bishops & $rooks) {
		warn "Bishops and rooks overlap.\n";
		undef $consistent;
	}
	if ($bishops & $queens) {
		warn "Bishops and queens overlap.\n";
		undef $consistent;
	}
	if ($bishops & $kings) {
		warn "Bishops and kings overlap.\n";
		undef $consistent;
	}
	if ($queens & $kings) {
		warn "Queens and kings overlap.\n";
		undef $consistent;
	}

	return $self if $consistent;

	warn $self->dumpAll;

	return;
}


sub pieceAtSquare {
	my ($self, $square) = @_;

	return $self->pieceAtShift($self->squareToShift($square));
}

sub pieceAtCoordinates {
	my ($self, $file, $rank) = @_;

	return $self->pieceAtShift($self->coordinatesToShift($file, $rank));
}

sub pieceAtShift {
	my ($self, $shift) = @_;

	return if $shift < 0;
	return if $shift > 63;

	my $mask = 1 << $shift;
	my ($piece, $color) = (CP_NO_PIECE);
	if ($mask & $self->[CP_POS_WHITE_PIECES]) {
		$color = CP_WHITE;
	} elsif ($mask & $self->[CP_POS_BLACK_PIECES]) {
		$color = CP_BLACK;
	}

	if (defined $color) {
		if ($mask & $self->[CP_POS_PAWNS]) {
			$piece = CP_PAWN;
		} elsif ($mask & $self->[CP_POS_KNIGHTS]) {
			$piece = CP_KNIGHT;
		} elsif ($mask & $self->[CP_POS_BISHOPS]) {
			$piece = CP_BISHOP;
		} elsif ($mask & $self->[CP_POS_ROOKS]) {
			$piece = CP_ROOK;
		} elsif ($mask & $self->[CP_POS_QUEENS]) {
			$piece = CP_QUEEN;
		} else {
			$piece = CP_KING;
		}
	}

	if (wantarray) {
		return $piece, $color;
	} else {
		return $piece;
	}
}

sub moveLegal {
	my ($self, $move) = @_;

	if ($move =~ /[a-z]/i) {
		$move = $self->parseMove($move) or return;
	}

	my @legal_moves = $self->legalMoves;
	foreach my $legal_move (@legal_moves) {
		return $self if $self->moveEquivalent($legal_move, $move);
	}

	return;
}

sub applyMove {
	my ($self, $move) = @_;

	if ($move =~ /[a-z]/i) {
		$move = $self->parseMove($move) or return;
	}

	return $self->doMove($move);
}

sub unapplyMove {
	my ($self, $state) = @_;

	return if !ref $state;
	return if 'ARRAY' ne reftype $state;

	return $self->undoMove($state);
}

sub dumpAll {
	my ($self) = @_;

	my $pad19 = sub {
		my $str = $_;
		while (19 > length $str) {
			$str .= ' ';
		}

		return $str;
	};

	my $output = '';

	my $w_pieces = $self->dumpBitboard($self->[CP_POS_WHITE_PIECES]);
	my $b_pieces = $self->dumpBitboard($self->[CP_POS_BLACK_PIECES]);
	my @w_pieces = map { $pad19->() } split /\n/, $w_pieces;
	my @b_pieces = map { $pad19->() } split /\n/, $b_pieces;
	$output .= "  White               Black\n";
	for (my $i = 0; $i < @w_pieces; ++$i) {
		$output .= "$w_pieces[$i]   $b_pieces[$i]\n";
	}

	my $pawns = $self->dumpBitboard($self->[CP_POS_PAWNS]);
	my @pawns = map { $pad19->() } split /\n/, $pawns;
	my $knights = $self->dumpBitboard($self->[CP_POS_KNIGHTS]);
	my @knights = map { $pad19->() } split /\n/, $knights;
	$output .= "\n  Pawns               Knights\n";
	for (my $i = 0; $i < @pawns; ++$i) {
		$output .= "$pawns[$i]   $knights[$i]\n";
	}

	my $bishops = $self->dumpBitboard($self->[CP_POS_BISHOPS]);
	my @bishops = split /\n/, $bishops;
	my $rooks = $self->dumpBitboard($self->[CP_POS_ROOKS]);
	my @rooks = map { $pad19->() } split /\n/, $rooks;
	$output .= "\n  Bishops             Rooks\n";
	for (my $i = 0; $i < @bishops; ++$i) {
		$output .= "$bishops[$i]   $rooks[$i]\n";
	}

	my $queens = $self->dumpBitboard($self->[CP_POS_QUEENS]);
	my @queens = split /\n/, $queens;
	my $kings = $self->dumpBitboard($self->[CP_POS_KINGS]);
	my @kings = map { $pad19->() } split /\n/, $kings;
	$output .= "\n  Queens              Kings\n";
	for (my $i = 0; $i < @queens; ++$i) {
		$output .= "$queens[$i]   $kings[$i]\n";
	}

	return $output;
}

sub dumpInfo {
	my ($self) = @_;

	my $output = 'Castling: ';

	my $castling = $self->castlingRights;
	if ($castling) {
		$output .= 'K' if $castling & 0x1;
		$output .= 'Q' if $castling & 0x2;
		$output .= 'k' if $castling & 0x4;
		$output .= 'q' if $castling & 0x8;
	} else {
		$output .= '- ';
	}

	$output .= "\nTo move: ";
	if (CP_WHITE == $self->toMove) {
		$output .= "white\n";
	} else {
		$output .= "black\n";
	}

	$output .= 'En passant square: ';
	if ($self->enPassant) {
		$output .= $self->shiftToSquare($self->enPassanShift);
	} else {
		$output .= '-';
	}

	my ($checkers, $king_shift, $defence_bb) = $self->inCheck;
	if ($checkers) {
		$output .= "In check: yes\n";

		$output .= 'Check evasion strategies: ';
		if (!$defence_bb) {
			$output .= "king move only\n";
		} elsif ($checkers == $defence_bb) {
			$output .= "king move or capture\n";
		} else {
			$output .= "king move, capture, or block\n";
		}

		$output .= "Check defence squares:\n";
		$output .= $self->dumpBitboard($defence_bb);

		$output .= "Checkers:\n";
		$output .= $self->dumpBitboard($checkers);
	} else {
		$output .= "In check: no\n";
	}

	my $signature = $self->signature;
	$output .= "Signature: $signature\n";

	return $output;
}

sub movesCoordinateNotation {
	my ($class, @moves) = @_;

	foreach my $move (@moves) {
		$move = moveCoordinateNotation(undef, $move);
	}

	return @moves;
}

sub moveNumbers {
	my ($class);

	return @move_numbers;
}

sub kingAttackMask {
	return [@king_attack_masks];
}

sub knightAttackMask {
	return [@knight_attack_masks];
}

###########################################################################
# Generate lookup tables.
###########################################################################

# This would be slightly more efficient in one giant loop but with separate
# loops for each variable, it is easier to understand and maintain.

# King attack masks.
for my $shift (0 .. 63) {
	my ($file, $rank) = shiftToCoordinates undef, $shift;

	my $mask = 0;

	# East.
	$mask |= (1 << ($shift + 1)) if $file < 7;

	# South-east.
	$mask |= (1 << ($shift - 7)) if $file < 7 && $rank > 0;

	# South.
	$mask |= (1 << ($shift - 8)) if              $rank > 0;

	# South-west.
	$mask |= (1 << ($shift - 9)) if $file > 0 && $rank > 0;

	# West.
	$mask |= (1 << ($shift - 1)) if $file > 0;

	# North-west.
	$mask |= (1 << ($shift + 7)) if $file > 0 && $rank < 7;

	# North.
	$mask |= (1 << ($shift + 8)) if              $rank < 7;

	# North-east.
	$mask |= (1 << ($shift + 9)) if $file < 7 && $rank < 7;

	$king_attack_masks[$shift] = $mask;
}

# Knight attack masks.
for my $shift (0 .. 63) {
	my ($file, $rank) = shiftToCoordinates undef, $shift;

	my $mask = 0;

	# North-north-east.
	$mask |= (1 << ($shift + 17)) if $file < 7 && $rank < 6;

	# North-east-east.
	$mask |= (1 << ($shift + 10)) if $file < 6 && $rank < 7;

	# South-east-east.
	$mask |= (1 << ($shift -  6)) if $file < 6 && $rank > 0;

	# South-south-east.
	$mask |= (1 << ($shift - 15)) if $file < 7&&  $rank > 1;

	# South-south-west.
	$mask |= (1 << ($shift - 17)) if $file > 0 && $rank > 1;

	# South-west-west.
	$mask |= (1 << ($shift - 10)) if $file > 1 && $rank > 0;

	# North-west-west.
	$mask |= (1 << ($shift +  6)) if $file > 1 && $rank < 7;

	# North-north-west.
	$mask |= (1 << ($shift + 15)) if $file > 0 && $rank < 6;

	$knight_attack_masks[$shift] = $mask;
}

# Pawn masks.
my @white_pawn_single_masks;
for my $shift (0 .. 63) {
	push @white_pawn_single_masks, 1 << ($shift + 8);
}
my @white_pawn_double_masks;
for my $shift (0 .. 63) {
	if ($shift >= 8 && $shift <= 15) {
		push @white_pawn_double_masks, 1 << ($shift + 16);
	} else {
		push @white_pawn_double_masks, 0;
	}
}
my @white_pawn_capture_masks;
for my $shift (0 .. 63) {
	my ($file, $rank) = shiftToCoordinates undef, $shift;
	my $mask = 0;
	if ($file > 0) {
		$mask |= 1 << ($shift + 7);
	}
	if ($file < 7) {
		$mask |= 1 << ($shift + 9);
	}
	push @white_pawn_capture_masks, $mask;
}
$pawn_masks[CP_WHITE] = [\@white_pawn_single_masks, \@white_pawn_double_masks,
		\@white_pawn_capture_masks];

my @black_pawn_single_masks;
for my $shift (0 .. 63) {
	push @black_pawn_single_masks, 1 << ($shift - 8);
}
my @black_pawn_double_masks;
for my $shift (0 .. 63) {
	if ($shift >= 48 && $shift <= 55) {
		push @black_pawn_double_masks, 1 << ($shift - 16);
	} else {
		push @black_pawn_double_masks, 0;
	}
}
my @black_pawn_capture_masks;
for my $shift (0 .. 63) {
	my ($file, $rank) = shiftToCoordinates undef, $shift;
	my $mask = 0;
	if ($file > 0) {
		$mask |= 1 << ($shift - 9);
	}
	if ($file < 7) {
		$mask |= 1 << ($shift - 7);
	}
	push @black_pawn_capture_masks, $mask;
}
$pawn_masks[CP_BLACK] = [\@black_pawn_single_masks, \@black_pawn_double_masks,
		\@black_pawn_capture_masks];

# Map en passant squares to masks.
foreach my $shift (16 .. 23) {
	$ep_pawn_masks[$shift] = 1 << ($shift + 8);
}
foreach my $shift (40 .. 47) {
	$ep_pawn_masks[$shift] = 1 << ($shift - 8);
}

# Common lines.
for (my $i = 0; $i < 63; ++$i) {
	$common_lines[$i] = [];
	for (my $j = 0; $j < 63; ++$j) {
		$common_lines[$i]->[$j] = [];
	}
}

# Mask lookup for files and ranks for rooks.
foreach my $m1 (
	CP_1_MASK, CP_2_MASK, CP_3_MASK, CP_4_MASK,
	CP_5_MASK, CP_6_MASK, CP_7_MASK, CP_8_MASK,
	CP_A_MASK, CP_B_MASK, CP_C_MASK, CP_D_MASK,
	CP_E_MASK, CP_F_MASK, CP_G_MASK, CP_H_MASK,
) {
	my $m2 = $m1;
	my @shifts;
	while ($m2) {
		push @shifts, bitboardCountTrailingZbits(undef, $m2);
		$m2 = bitboardClearLeastSet(undef, $m2);
	}

	foreach my $i (@shifts) {
		foreach my $j (@shifts) {
			my $mask = $m1;
			# Clear all bits that are not between i and j.
			for my $k (0 .. 63) {
				my $d1 = $i - $k;
				my $d2 = $j - $k;
				if ($d1 * $d2 > 0) {
					$mask &= ~(1 << $k);
				}

			}
			$common_lines[$i]->[$j] = [1, $m1, $mask];
		}
	}
}

# Mask lookup for diagonals for bishops.  The short diagonals with 1 or 2
# squares only are omitted because they cannot be used for pins.
foreach my $m1 (
	CP_F1H3_MASK, CP_E1H4_MASK, CP_D1H5_MASK, CP_C1H6_MASK, CP_B1H7_MASK,
	CP_A1H8_MASK,
	CP_A2G8_MASK, CP_A3F8_MASK, CP_A4E8_MASK, CP_A5D8_MASK, CP_A6C8_MASK,
	CP_C1A3_MASK, CP_D1A4_MASK, CP_E1A5_MASK, CP_F1A6_MASK, CP_G1A7_MASK,
	CP_H1A8_MASK,
	CP_H2B8_MASK, CP_H3C8_MASK, CP_H4D8_MASK, CP_H5E8_MASK, CP_H6F8_MASK,
) {
	my $m2 = $m1;
	my @shifts;
	while ($m2) {
		push @shifts, bitboardCountTrailingZbits(undef, $m2);
		$m2 = bitboardClearLeastSet(undef, $m2);
	}

	foreach my $i (@shifts) {
		foreach my $j (@shifts) {
			my $mask = $m1;
			# Clear all bits that are not between i and j.
			for my $k (0 .. 63) {
				my $d1 = $i - $k;
				my $d2 = $j - $k;
				if ($d1 * $d2 > 0) {
					$mask &= ~(1 << $k);
				}

			}
			$common_lines[$i]->[$j] = [0, $m1, $mask];
		}
	}
}


# Zobrist keys.
for (my $i = 0; $i < 768; ++$i) {
	push @zk_pieces, RNG();
}
for (my $i = 0; $i < 16; ++$i) {
	push @zk_castling, RNG();
}
for (my $i = 0; $i < 8; ++$i) {
	push @zk_ep_files, RNG();
}
$zk_color = RNG();

$castling_rook_zk_updates[CP_C1] = $zk_pieces[384] ^ $zk_pieces[387];
$castling_rook_zk_updates[CP_G1] = $zk_pieces[389] ^ $zk_pieces[391];
$castling_rook_zk_updates[CP_C8] = $zk_pieces[504] ^ $zk_pieces[507];
$castling_rook_zk_updates[CP_G8] = $zk_pieces[509] ^ $zk_pieces[511];

# The indices are the target squares of the king.
$castling_rook_move_masks[CP_C1] = CP_1_MASK & (CP_A_MASK | CP_D_MASK);
$castling_rook_move_masks[CP_G1] = CP_1_MASK & (CP_H_MASK | CP_F_MASK);
$castling_rook_move_masks[CP_C8] = CP_8_MASK & (CP_A_MASK | CP_D_MASK);
$castling_rook_move_masks[CP_G8] = CP_8_MASK & (CP_H_MASK | CP_F_MASK);

$castling_rook_to_mask[CP_C1] = 1 << CP_D1;
$castling_rook_to_mask[CP_G1] = 1 << CP_F1;
$castling_rook_to_mask[CP_C8] = 1 << CP_D8;
$castling_rook_to_mask[CP_G8] = 1 << CP_F8;

# The indices are the original squares of the rooks.
@castling_rights_rook_masks = (-1) x 64;
$castling_rights_rook_masks[CP_H1] = ~0x1;
$castling_rights_rook_masks[CP_A1] = ~0x2;
$castling_rights_rook_masks[CP_H8] = ~0x4;
$castling_rights_rook_masks[CP_A8] = ~0x8;

my @piece_values = (0, CP_PAWN_VALUE, CP_KNIGHT_VALUE, CP_BISHOP_VALUE,
	CP_ROOK_VALUE, CP_QUEEN_VALUE);
@material_deltas = (0) x (1 + (1 | (CP_QUEEN << 1) | (CP_QUEEN << 4)));
foreach my $captured (CP_NO_PIECE, CP_PAWN, CP_KNIGHT, CP_BISHOP, CP_ROOK, CP_QUEEN) {
	$material_deltas[CP_WHITE | ($captured << 4)] = ($piece_values[$captured] << 31);
	$material_deltas[CP_BLACK | ($captured << 4)] = (-$piece_values[$captured] << 31);
	foreach my $promote (CP_KNIGHT, CP_BISHOP, CP_ROOK, CP_QUEEN) {
		$material_deltas[CP_WHITE | ($promote << 1) | ($captured << 4)] =
			($piece_values[$captured] + $piece_values[$promote] - CP_PAWN_VALUE) << 31;
		$material_deltas[CP_BLACK | ($promote << 1) | ($captured << 4)] =
			-($piece_values[$captured] + $piece_values[$promote] - CP_PAWN_VALUE) << 31;
	}
}

# Obscured masks.
#
# If a sliding pieces moves from FROM to TO, sliding pieces of the same type
# may now also attack TO.  The obscured_masks give the answer to the question
# which squares had been previously obscured.
foreach my $from (0 .. 63) {
	$obscured_masks[$from] = [(0) x 64];
	my $from_mask = 1 << $from;
	foreach my $to (0 .. 63) {
		my $common = $common_lines[$from]->[$to] or next;

		my ($type, $diagonal, $common) = @$common;

		# If $from is less than $to, all bits of the diagonal that are less
		# than from constitute the obscure squares, otherwise all bits that are
		# greater than from.
		if ($from < $to) {
			$obscured_masks[$from]->[$to] = $diagonal & ($from_mask - 1);
		} else {
			$obscured_masks[$from]->[$to] = $diagonal & ~($from_mask - 1) & ~$from_mask;
		}
	}
}

# Moves:
# 0-5: to
# 6-11: from
# 12-14: promote
# 15-17: piece
# 18-20: captured
# 21: color
my $gen_moves = sub {
	my ($moves, $piece, $from, $to, $color) = @_;
	my $move = $to | ($from << 6) | ($piece << 15) | ($color << 21);
	push @$moves, $move if $piece != CP_PAWN;
	push @$moves, $move | (CP_PAWN << 18);
	push @$moves, $move | (CP_KNIGHT << 18);
	push @$moves, $move | (CP_BISHOP << 18);
	push @$moves, $move | (CP_ROOK << 18);
	push @$moves, $move | (CP_QUEEN << 18);

	# En passant.
	if ($color == CP_WHITE && $piece == CP_PAWN && $to >= CP_A6 && $to <= CP_H6) {
		push @$moves, $move | (CP_KING << 18);
	} elsif ($color == CP_BLACK && $piece == CP_PAWN && $to >= CP_A3 && $to <= CP_H3) {
		push @$moves, $move | (CP_KING << 18);
	}
};
my $gen_promotions = sub {
	my ($moves, $from, $color) = @_;
	my $move = ($from << 6) | (CP_PAWN << 15) | ($color << 21);
	my $to = $color ? $from - 8 : $from + 8;
	# Normal promotions.
	push @$moves, $move | (CP_QUEEN << 12) | $to;
	push @$moves, $move | (CP_ROOK << 12) | $to;
	push @$moves, $move | (CP_BISHOP << 12) | $to;
	push @$moves, $move | (CP_KNIGHT << 12) | $to;
	# Promotions with captures to the left-side.
	if (($from & 0x7) != CP_FILE_A) {
		$to = $color ? $from - 9 : $from + 7;
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_QUEEN << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_QUEEN << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_QUEEN << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_QUEEN << 18);
	}
	# Promotions with captures to the right-side.
	if (($from & 0x7) != CP_FILE_H) {
		$to = $color ? $from - 7 : $from + 9;
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_QUEEN << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_QUEEN << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_QUEEN << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_QUEEN << 18);
	}
};

foreach my $file (CP_FILE_A .. CP_FILE_H) {
	my $mb = 1 << 21;
	foreach my $rank (CP_RANK_1 .. CP_RANK_8) {
		my @moves;
		my $from = coordinatesToShift(undef, $file, $rank);
		my $move_from = $from << 6;

		# Pawn moves.
		if ($rank == CP_RANK_2) {
			# White single step.
			push @moves, ((CP_PAWN << 15) | ($move_from) | $from + 8);
			# White double step.
			push @moves, ((CP_PAWN << 15) | ($move_from) | $from + 16);
			# White captures.
			$gen_moves->(\@moves, CP_PAWN, $from, $from + 7, CP_WHITE)
				if $file != CP_FILE_A;
			$gen_moves->(\@moves, CP_PAWN, $from, $from + 9, CP_WHITE)
				if $file != CP_FILE_H;
			# Black promotions.
			$gen_promotions->(\@moves, $from, CP_BLACK);
		} elsif ($rank > CP_RANK_2 && $rank < CP_RANK_7) {
			# White single steps.
			push @moves, ((CP_PAWN << 15) | ($move_from) | $from + 8);
			# White captures.
			$gen_moves->(\@moves, CP_PAWN, $from, $from + 7, CP_WHITE)
				if $file != CP_FILE_A;
			$gen_moves->(\@moves, CP_PAWN, $from, $from + 9, CP_WHITE)
				if $file != CP_FILE_H;
			# Black single steps.
			push @moves, ((CP_PAWN << 15) | ($move_from) | $from - 8) | $mb;
			# Black captures.
			$gen_moves->(\@moves, CP_PAWN, $from, $from - 9, CP_BLACK)
				if $file != CP_FILE_A;
			$gen_moves->(\@moves, CP_PAWN, $from, $from - 7, CP_BLACK)
				if $file != CP_FILE_H;
		} elsif ($rank == CP_RANK_7) {
			# Black single step.
			push @moves, ((CP_PAWN << 15) | ($move_from) | $from - 8) | $mb;
			# Black double step.
			push @moves, ((CP_PAWN << 15) | ($move_from) | $from - 16) | $mb;
			# Black captures.
			$gen_moves->(\@moves, CP_PAWN, $from, $from - 9, CP_BLACK)
				if $file != CP_FILE_A;
			$gen_moves->(\@moves, CP_PAWN, $from, $from - 7, CP_BLACK)
				if $file != CP_FILE_H;
			# White promotions.
			$gen_promotions->(\@moves, $from, CP_WHITE);
		}

		# Knight moves.
		my $attack_mask = $knight_attack_masks[$from];
		while ($attack_mask) {
			my $to = bitboardCountTrailingZbits(undef, $attack_mask);
			$gen_moves->(\@moves, CP_KNIGHT, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_KNIGHT, $from, $to, CP_BLACK);
			$attack_mask = bitboardClearLeastSet(undef, $attack_mask);
		}

		# Bishop and bishop-style queen moves.
		my ($to, $to_file, $to_rank);
		# North-east.
		$to = $from;
		for (my ($to_file, $to_rank) = ($file + 1, $rank + 1);
				$to_file <= CP_FILE_H && $to_rank <= CP_RANK_8;
				++$to_file, ++$to_rank) {
			$to += 9;
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_BLACK);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_BLACK);
		}
		# South-east.
		$to = $from;
		for (my ($to_file, $to_rank) = ($file + 1, $rank - 1);
				$to_file <= CP_FILE_H && $to_rank >= CP_RANK_1;
				++$to_file, --$to_rank) {
			$to -= 7;
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_BLACK);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_BLACK);
		}
		# South-west.
		$to = $from;
		for (my ($to_file, $to_rank) = ($file - 1, $rank - 1);
				$to_file >= CP_FILE_A && $to_rank >= CP_RANK_1;
				--$to_file, --$to_rank) {
			$to -= 9;
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_BLACK);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_BLACK);
		}
		# North-west.
		$to = $from;
		for (my ($to_file, $to_rank) = ($file - 1, $rank + 1);
				$to_file >= CP_FILE_A && $to_rank <= CP_RANK_8;
				--$to_file, ++$to_rank) {
			$to += 7;
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_BLACK);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_BLACK);
		}

		# Rook and rook-style queen moves.
		foreach my $dist_to (-7 .. -1, +1 .. +7) {
			my $to = $from + $dist_to;
			next if $to < 0 || $to > 63;
			if (($from & 0x38) == ($to & 0x38)) {
				$gen_moves->(\@moves, CP_ROOK, $from, $to, CP_WHITE);
				$gen_moves->(\@moves, CP_ROOK, $from, $to, CP_BLACK);
				$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_WHITE);
				$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_BLACK);
			}
		}
		foreach my $dist_to (-7 .. -1, +1 .. +7) {
			my $to = $from + 8 * $dist_to;
			next if $to < 0 || $to > 63;
			if (($from & 0x7) == ($to & 0x7)) {
				$gen_moves->(\@moves, CP_ROOK, $from, $to, CP_WHITE);
				$gen_moves->(\@moves, CP_ROOK, $from, $to, CP_BLACK);
				$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_WHITE);
				$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_BLACK);
			}
		}

		# King moves.
		$attack_mask = $king_attack_masks[$from];
		while ($attack_mask) {
			my $to = bitboardCountTrailingZbits(undef, $attack_mask);
			$gen_moves->(\@moves, CP_KING, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_KING, $from, $to, CP_BLACK);
			$attack_mask = bitboardClearLeastSet(undef, $attack_mask);
		}

		# Castlings.
		if ($from == CP_E1) {
			push @moves, ((CP_KING << 15) | (CP_E1 << 6) | CP_G1);
			push @moves, ((CP_KING << 15) | (CP_E1 << 6) | CP_C1);
		} elsif ($from == CP_E8) {
			push @moves, ((CP_KING << 15) | (CP_E8 << 6) | CP_G8) | $mb;
			push @moves, ((CP_KING << 15) | (CP_E8 << 6) | CP_C8) | $mb;
		}

		push @move_numbers, @moves;
	}
}

# Magic moves.
sub __initmagicmoves_occ {
	my ($squares, $linocc) = @_;

	my $ret = 0;
	for (my $i = 0; $i < @$squares; ++$i) {
		if ($linocc & (1 << $i)) {
			$ret |= (1 << $squares->[$i]);
		}
	}

	return $ret;
}

sub __initmagicmoves_Rmoves {
	my ($square, $occ) = @_;

	my $ret = 0;
	my $bit;
	my $bit_8_mask = (1 << (64 - 8)) - 1;
	my $bit_1_mask = (1 << (64 - 1)) - 1;
	my $rowbits = (0xFF) << (8 * ($square / 8));

	$bit = 1 << $square;
	do {
		$bit <<= 8;
		$ret |= $bit;
	} while ($bit && !($bit & $occ));

	$bit = 1 << $square;
	do {
		$bit >>= 8;
		$bit &= $bit_8_mask;
		$ret |= $bit;
	} while ($bit && !($bit & $occ));

	$bit = 1 << $square;
	{
		do {
			$bit <<= 1;
			if ($bit & $rowbits) {
				$ret |= $bit;
			} else {
				last;
			}
		} while (!($bit & $occ));
	}

	$bit = (1 << $square);
	{
		do {
			$bit >>= 1;
			$bit &= $bit_1_mask;
			if ($bit & $rowbits) {
				$ret |= $bit; }
			else { 
				last;
			}
		} while (!($bit & $occ));
	}
	
	return $ret;
}

sub __initmagicmoves_Bmoves {
	my ($square, $occ) = @_;
	my $ret = 0;
	my $bit;
	my $bit2;
	my $rowbits = ((0xFF) << (8 * ($square / 8)));
	my $bit_7_mask = (1 << (64 - 7)) - 1;
	my $bit_9_mask = (1 << (64 - 9)) - 1;
	my $bit2_sign_mask = (1 << 63) - 1;

	$bit = (1 << $square);
	$bit2 = $bit;
	{
		do {
			$bit <<= 8 - 1;
			$bit2 >>= 1;
			$bit2 &= $bit2_sign_mask;
			if ($bit2 & $rowbits) {
				$ret |= $bit;
			} else {
				last;
			}
		} while ($bit && !($bit & $occ));
	}

	$bit = (1 << $square);
	$bit2 = $bit;
	{
		do {
			$bit <<= 8 + 1;
			$bit2 <<= 1;
			if ($bit2 & $rowbits) {
				$ret |= $bit;
			} else {
				last;
			}
		} while ($bit && !($bit & $occ));
	}

	$bit = (1 << $square);
	$bit2 = $bit;
	{
		do {
			$bit >>= 8 - 1;
			$bit &= $bit_7_mask;
			$bit2 <<= 1;
			if ($bit2 & $rowbits)
				{
					$ret |= $bit;
				} else {
					last;
				} 
		} while ($bit && !($bit & $occ));
	}

	$bit = (1 << $square);
	$bit2 = $bit;
	{
		do {
			$bit >>= 8 + 1;
			$bit &= $bit_9_mask;
			$bit2 >>= 1;
			$bit2 &= $bit2_sign_mask;
			if ($bit2 & $rowbits) {
				$ret |= $bit;
			} else {
				last;
			}
		} while ($bit && !($bit & $occ));
	}

	return $ret;
}

# Init magicmoves.
my @__initmagicmoves_bitpos64_database = (
	63,  0, 58,  1, 59, 47, 53,  2,
	60, 39, 48, 27, 54, 33, 42,  3,
	61, 51, 37, 40, 49, 18, 28, 20,
	55, 30, 34, 11, 43, 14, 22,  4,
	62, 57, 46, 52, 38, 26, 32, 41,
	50, 36, 17, 19, 29, 10, 13, 21,
	56, 45, 25, 31, 35, 16,  9, 12,
	44, 24, 15,  8, 23,  7,  6,  5
);

use constant MINIMAL_B_BITS_SHIFT => 55;
use constant MINIMAL_R_BITS_SHIFT => 52;

my $b_bits_shift_mask = (1 << (64 - MINIMAL_B_BITS_SHIFT)) - 1;
my $r_bits_shift_mask = (1 << (64 - MINIMAL_R_BITS_SHIFT)) - 1;
my $mask58 = (1 << (64 - 58)) - 1;
for (my $i = 0; $i < 64; ++$i) {
	my @squares;
	my $numsquares = 0;
	my $temp = $magicmoves_b_mask[$i];

	while ($temp) {
		my $bit = $temp & -$temp;
		$squares[$numsquares++] = $__initmagicmoves_bitpos64_database[$mask58 & (($bit * 0x07EDD5E59A4E28C2) >> 58)];
		$temp ^= $bit;
	}
	for ($temp = 0; $temp < (1 << $numsquares); ++$temp) {
		my $tempocc = __initmagicmoves_occ(\@squares, $temp);
		my $j = (($tempocc) * $magicmoves_b_magics[$i]);
		my $k = ($j >> MINIMAL_B_BITS_SHIFT) & $b_bits_shift_mask;
		$magicmovesbdb[$i]->[$k]
				= __initmagicmoves_Bmoves($i, $tempocc);
	}
}

for (my $i = 0; $i < 64; ++$i) {
	my @squares;
	my $numsquares = 0;
	my $temp = $magicmoves_r_mask[$i];
	while ($temp) {
			my $bit = $temp & -$temp;
			$squares[$numsquares++] = $__initmagicmoves_bitpos64_database[$mask58 & (($bit * 0x07EDD5E59A4E28C2) >> 58)];
			$temp ^= $bit;
	}
	for ($temp = 0; $temp < 1 << $numsquares; ++$temp) {
		my $tempocc = __initmagicmoves_occ(\@squares, $temp);

		my $j = (($tempocc) * $magicmoves_r_magics[$i]);
		my $k = ($j >> MINIMAL_R_BITS_SHIFT) & $r_bits_shift_mask;
		$magicmovesrdb[$i][$k] = __initmagicmoves_Rmoves($i, $tempocc);
	}
}

1;
