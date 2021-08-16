#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
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

package Chess::Position;

use strict;
use integer;
use overload '""' => sub { shift->toFEN };

use Locale::TextDomain qw('Chess-Position');
use Chess::Position::Macro;

use base qw(Exporter);

my @export_accessors = qw(
	CP_POS_W_PIECES CP_POS_B_PIECES
	CP_POS_KINGS CP_POS_ROOKS CP_POS_BISHOPS CP_POS_KNIGHTS CP_POS_PAWNS
	CP_POS_TO_MOVE
	CP_POS_W_KCASTLE CP_POS_W_QCASTLE CP_POS_B_KCASTLE CP_POS_B_QCASTLE
	CP_POS_EP_SHIFT CP_POS_HALF_MOVE_CLOCK CP_POS_HALF_MOVES
	CP_POS_W_KING_SHIFT CP_POS_B_KING_SHIFT
	CP_POS_IN_CHECK
);

my @export_board = qw(
	CP_FILE_A CP_FILE_B CP_FILE_C CP_FILE_D
	CP_FILE_E CP_FILE_F CP_FILE_G CP_FILE_H
	CP_RANK_1 CP_RANK_2 CP_RANK_3 CP_RANK_4
	CP_RANK_5 CP_RANK_6 CP_RANK_7 CP_RANK_8
	CP_A_MASK CP_B_MASK CP_C_MASK CP_D_MASK
	CP_E_MASK CP_F_MASK CP_G_MASK CP_H_MASK
	CP_1_MASK CP_2_MASK CP_3_MASK CP_4_MASK
	CP_5_MASK CP_6_MASK CP_7_MASK CP_8_MASK
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

our @EXPORT_OK = (@export_pieces, @export_board, @export_accessors,
		@export_magicmoves);

our %EXPORT_TAGS = (
	accessors => [@export_accessors],
	pieces => [@export_pieces],
	board => [@export_board],
	magicmoves => [@export_magicmoves],
	all => [@EXPORT_OK],
);

# Accessor indices.
use constant CP_POS_W_PIECES => 0;
use constant CP_POS_B_PIECES => 1;
use constant CP_POS_KINGS => 2;
use constant CP_POS_ROOKS => 3;
use constant CP_POS_BISHOPS => 4;
use constant CP_POS_KNIGHTS => 5;
use constant CP_POS_PAWNS => 6;
use constant CP_POS_TO_MOVE => 7;
use constant CP_POS_W_KCASTLE => 8;
use constant CP_POS_B_KCASTLE => 9;
use constant CP_POS_W_QCASTLE => 10;
use constant CP_POS_B_QCASTLE => 11;
use constant CP_POS_EP_SHIFT => 12;
use constant CP_POS_HALF_MOVE_CLOCK => 13;
use constant CP_POS_HALF_MOVES => 14;
use constant CP_POS_W_KING_SHIFT => 15;
use constant CP_POS_B_KING_SHIFT => 16;
use constant CP_POS_IN_CHECK => 17;

# Board.
use constant CP_A_MASK => 0x8080808080808080;
use constant CP_B_MASK => 0x4040404040404040;
use constant CP_C_MASK => 0x2020202020202020;
use constant CP_D_MASK => 0x1010101010101010;
use constant CP_E_MASK => 0x0808080808080808;
use constant CP_F_MASK => 0x0404040404040404;
use constant CP_G_MASK => 0x0202020202020202;
use constant CP_H_MASK => 0x0101010101010101;

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
use constant CP_KNIGHT_VALUE => 300;
use constant CP_BISHOP_VALUE => 300;
use constant CP_ROOK_VALUE => 500;
use constant CP_QUEEN_VALUE => 900;

use constant CP_PIECE_CHARS => [
	['', 'P', 'N', 'B', 'R', 'Q', 'K'],
	['', 'p', 'n', 'b', 'r', 'q', 'k'],
];

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

my @castling_aux_data = (
	# White.
	[
		# From shift.
		3,
		# From mask.
		(CP_E_MASK & CP_1_MASK),
		# King-side crossing square.
		(CP_F_MASK & CP_1_MASK),
		# King-side king's destination square.
		1,
		# Queen-side crossing mask.
		(CP_D_MASK & CP_1_MASK),
		# Queen-side king's destination square.
		5,
		# Queen-side rook crossing mask.
		(CP_B_MASK & CP_1_MASK),
	],
	# Black.
	[
		# From shift.
		59,
		# From mask.
		(CP_E_MASK & CP_8_MASK),
		# King-side crossing mask.
		(CP_F_MASK & CP_8_MASK),
		# King-side king's destination square.
		57,
		# Queen-side crossing mask.
		(CP_D_MASK & CP_8_MASK),
		# Queen-side king's destination square.
		61,
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

# Magic moves.
my @magicmoves_r_shift = (
	52, 53, 53, 53, 53, 53, 53, 52,
	53, 54, 54, 54, 54, 54, 54, 53,
	53, 54, 54, 54, 54, 54, 54, 53,
	53, 54, 54, 54, 54, 54, 54, 53,
	53, 54, 54, 54, 54, 54, 54, 53,
	53, 54, 54, 54, 54, 54, 54, 53,
	53, 54, 54, 54, 54, 54, 54, 53,
	53, 54, 54, 53, 53, 53, 53, 53
);

my @magicmoves_r_magics = (
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

my @magicmoves_r_mask = (
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

my @magicmoves_b_shift = (
	58, 59, 59, 59, 59, 59, 59, 58,
	59, 59, 59, 59, 59, 59, 59, 59,
	59, 59, 57, 57, 57, 57, 59, 59,
	59, 59, 57, 55, 55, 57, 59, 59,
	59, 59, 57, 55, 55, 57, 59, 59,
	59, 59, 57, 57, 57, 57, 59, 59,
	59, 59, 59, 59, 59, 59, 59, 59,
	58, 59, 59, 59, 59, 59, 59, 58
);

my @magicmoves_b_magics = (
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

my @magicmoves_b_mask = (
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

my @magicmovesbdb;
my @magicmovesrdb;

use constant CP_MAGICMOVES_B_MAGICS => \@magicmoves_b_magics;
use constant CP_MAGICMOVES_R_MAGICS => \@magicmoves_r_magics;
use constant CP_MAGICMOVES_B_MASK => \@magicmoves_b_mask;
use constant CP_MAGICMOVES_R_MASK => \@magicmoves_r_mask;
use constant CP_MAGICMOVESBDB => \@magicmovesbdb;
use constant CP_MAGICMOVESRDB => \@magicmovesrdb;

sub new {
	my ($class, $fen) = @_;

	return $class->newFromFEN($fen) if defined $fen && length $fen;

	my $self = bless [], $class;
	cp_pos_w_pieces($self) = CP_1_MASK | CP_2_MASK;
	cp_pos_b_pieces($self) = CP_8_MASK | CP_7_MASK,
	cp_pos_kings($self) = (CP_1_MASK | CP_8_MASK) & CP_E_MASK;
	cp_pos_rooks($self) = ((CP_A_MASK | CP_D_MASK | CP_H_MASK) & CP_1_MASK)
			| ((CP_A_MASK | CP_D_MASK | CP_H_MASK) & CP_8_MASK),
	cp_pos_bishops($self) = ((CP_C_MASK | CP_D_MASK | CP_F_MASK) & CP_1_MASK)
			| ((CP_C_MASK | CP_D_MASK | CP_F_MASK) & CP_8_MASK),
	cp_pos_knights($self) = ((CP_B_MASK | CP_G_MASK) & CP_1_MASK)
			| ((CP_B_MASK | CP_G_MASK) & CP_8_MASK),
	cp_pos_pawns($self) = CP_2_MASK | CP_7_MASK,
	cp_pos_to_move($self) = CP_WHITE;
	cp_pos_w_kcastle($self) = 1;
	cp_pos_w_qcastle($self) = 1;
	cp_pos_b_kcastle($self) = 1;
	cp_pos_b_qcastle($self) = 1;
	cp_pos_ep_shift($self) = 0;
	cp_pos_half_move_clock($self) = 0;
	cp_pos_half_moves($self) = 0;

	$self->update;

	return $self;
}

sub newFromFEN {
	my ($class, $fen) = @_;

	my ($pieces, $to_move, $castling, $ep_square, $hmc, $moveno)
			= split /[ \t]+/, $fen;
	$ep_square = '-' if !defined $ep_square;
	$hmc = 0 if !defined $hmc;
	$moveno = 1 if !defined $moveno;

	if (!(defined $pieces && defined $to_move && defined $castling)) {
		die __"Illegal FEN: Incomplete.\n";
	}

	my @ranks = split '/', $pieces;
	die __"Illegal FEN: FEN does not have exactly eight ranks.\n"
		if @ranks != 8;
	
	my $shift = 63;
	my $w_pieces = 0;
	my $b_pieces = 0;
	my $kings = 0;
	my $rooks = 0;
	my $knights = 0;
	my $bishops = 0;
	my $pawns = 0;

	my $shift = 63;
	my $rankno = 7;
	foreach my $rank (@ranks) {
		my @chars = split '', $rank;
		foreach my $char (@chars) {
			if ('1' le $char && '8' ge $char) {
				$shift -= $char;
				next;
			}

			my $mask = 1 << $shift;
			if ('P' eq $char) {
				$w_pieces |= $mask;
				$pawns |= $mask;
			} elsif ('p' eq $char) {
				$b_pieces |= $mask;
				$pawns |= $mask;
			} elsif ('N' eq $char) {
				$w_pieces |= $mask;
				$knights |= $mask;
			} elsif ('n' eq $char) {
				$b_pieces |= $mask;
				$knights |= $mask;
			} elsif ('B' eq $char) {
				$w_pieces |= $mask;
				$bishops |= $mask;
			} elsif ('b' eq $char) {
				$b_pieces |= $mask;
				$bishops |= $mask;
			} elsif ('R' eq $char) {
				$w_pieces |= $mask;
				$rooks |= $mask;
			} elsif ('r' eq $char) {
				$b_pieces |= $mask;
				$rooks |= $mask;
			} elsif ('K' eq $char) {
				$w_pieces |= $mask;
				$kings |= $mask;
			} elsif ('k' eq $char) {
				$b_pieces |= $mask;
				$kings |= $mask;
			} elsif ('Q' eq $char) {
				$w_pieces |= $mask;
				$rooks |= $mask;
				$bishops |= $mask;
			} elsif ('q' eq $char) {
				$b_pieces |= $mask;
				$rooks |= $mask;
				$bishops |= $mask;
			} else {
				die __x("Illegal FEN: Illegal piece/number '{x}'.\n",
						x => $char);
			}
			--$shift;

		}

		if ($rankno-- << 3 != $shift + 1) {
			die __x("Illegal FEN: Incomplete or overpopulated rank '{rank}'.\n",
				rank => $rank);
		}
	}

	my $popcount;

	cp_bb_popcount $w_pieces & $kings, $popcount;
	if ($popcount != 1) {
		die __"Illegal FEN: White must have exactly one king.\n";
	}
	cp_bb_popcount $b_pieces & $kings, $popcount;
	if ($popcount != 1) {
		die __"Illegal FEN: Black must have exactly one king.\n";
	}

	my $self = bless [], $class;

	$self->[CP_POS_W_PIECES] = $w_pieces;
	$self->[CP_POS_B_PIECES] = $b_pieces;
	$self->[CP_POS_KINGS] = $kings;
	$self->[CP_POS_ROOKS] = $rooks;
	$self->[CP_POS_BISHOPS] = $bishops;
	$self->[CP_POS_KNIGHTS] = $knights;
	$self->[CP_POS_PAWNS] = $pawns;

	if ('w' eq lc $to_move) {
		$self->[CP_POS_TO_MOVE] = CP_WHITE;
	} elsif ('b' eq lc $to_move) {
		$self->[CP_POS_TO_MOVE] = CP_BLACK;
	} else {
		die __x"Illegal FEN: Side to move is neither 'w' nor 'b'.\n";
	}

	$self->[CP_POS_W_KCASTLE] = 0;
	$self->[CP_POS_W_QCASTLE] = 0;
	$self->[CP_POS_B_KCASTLE] = 0;
	$self->[CP_POS_B_QCASTLE] = 0;
	if (!length $castling) {
		die __"Illegal FEN: Missing castling state.\n";
	}
	if ($castling !~ /^(?:-|K?Q?k?q?)/) {
		die __x("Illegal FEN: Illegal castling state '{state}'.\n",
				state => $castling);
	}

	if ($castling =~ /K/) {
		$self->[CP_POS_W_KCASTLE] = 1;
	}
	if ($castling =~ /Q/) {
		$self->[CP_POS_W_QCASTLE] = 1;
	}
	if ($castling =~ /k/) {
		$self->[CP_POS_B_KCASTLE] = 1;
	}
	if ($castling =~ /q/) {
		$self->[CP_POS_B_QCASTLE] = 1;
	}

	# FIXME! Correct castling state if king or rook has moved.

	if ('-' eq $ep_square) {
		$self->[CP_POS_EP_SHIFT] = 0;
	} elsif ($self->[CP_POS_TO_MOVE] == CP_WHITE
	         && $ep_square !~ /^[a-h]6$/) {
		die __"Illegal FEN: En passant square must be on 6th rank with white to move.\n";
	} elsif ($self->[CP_POS_TO_MOVE] == CP_BLACK
	         && $ep_square !~ /^[a-h]3$/) {
		die __"Illegal FEN: En passant square must be on 3rd rank with black to move.\n";
	} else {
		$self->[CP_POS_EP_SHIFT] = $self->squareToShift($ep_square);
	}

	# FIXME! Check that there is a pawn of the right color on the 5th/4th
	# rank of the EP square!

	if ($hmc !~ /^0|[1-9][0-9]+$/) {
		die __x("Illegal FEN: Illegal half-move clock '{hmc}'.\n", hmc => $hmc);
	}
	$self->[CP_POS_HALF_MOVE_CLOCK] = $hmc;

	if ($moveno !~ /^[1-9][0-9]*$/) {
		die __x("Illegal FEN: Illegal move number '{num}'.\n", num => $moveno);
	}

	if ($self->[CP_POS_TO_MOVE] == CP_WHITE) {
			$self->[CP_POS_HALF_MOVES] = ($moveno - 1) << 1;
	} else {
			$self->[CP_POS_HALF_MOVES] = (($moveno - 1) << 1) + 1;
	}

	$self->update;

	# FIXME! Check that side not to move is not in check.

	return $self;
}

sub toFEN {
	my ($self) = @_;

	my $w_pieces = cp_pos_w_pieces($self);
	my $b_pieces = cp_pos_b_pieces($self);
	my $pieces = $w_pieces | $b_pieces;
	my $pawns = cp_pos_pawns($self);
	my $bishops = cp_pos_bishops($self);
	my $knights = cp_pos_knights($self);
	my $rooks = cp_pos_rooks($self);

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
						if ($mask & $rooks) {
							$fen .= 'Q';
						} else {
							$fen .= 'B';
						}
					} elsif ($mask & $rooks) {
						$fen .= 'R';
					} else {
						$fen .= 'K';
					}
				} elsif ($mask & $b_pieces) {
					if ($mask & $pawns) {
						$fen .= 'p';
					} elsif ($mask & $knights) {
						$fen .= 'n';
					} elsif ($mask & $bishops) {
						if ($mask & $rooks) {
							$fen .= 'q';
						} else {
							$fen .= 'b';
						}
					} elsif ($mask & $rooks) {
						$fen .= 'r';
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

	$fen .= (cp_pos_to_move($self) == CP_WHITE) ? ' w ' : ' b ';

	my $w_kcastle = cp_pos_w_kcastle($self) || 0;
	my $w_qcastle = cp_pos_w_kcastle($self) || 0;
	my $b_kcastle = cp_pos_w_kcastle($self) || 0;
	my $b_qcastle = cp_pos_w_kcastle($self) || 0;

	my $castle = '';
	$castle .= 'K' if $w_kcastle;
	$castle .= 'Q' if $w_qcastle;
	$castle .= 'k' if $b_kcastle;
	$castle .= 'q' if $b_qcastle;
	$castle ||= '-';

	$fen .= $castle . ' ';

	if (cp_pos_ep_shift $self) {
		$fen .= $self->shiftToSquare(cp_pos_ep_shift $self);
	} else {
		$fen .= '-';
	}

	$fen .= sprintf ' %u %u', cp_pos_half_move_clock($self),
			1 + (cp_pos_half_moves($self) >> 1);

	return $fen;
}

sub pseudoLegalMoves {
	my ($self) = @_;

	my $to_move = cp_pos_to_move $self;
	my $my_pieces = $self->[$to_move];
	my $her_pieces = $self->[!$to_move];
	my $occupancy = $my_pieces | $her_pieces;
	my $empty = ~$occupancy;

	my (@moves, $target_mask, $base_move);

	# Generate castlings.
	my $king_mask = $my_pieces & cp_pos_kings $self;
	my ($king_from, $king_from_mask, $king_side_crossing_mask,
			$king_side_dest_shift,
			$queen_side_crossing_mask, $queen_side_dest_shift,
			$queen_side_rook_crossing_mask)
			= @{$castling_aux_data[$to_move]};
	if ($king_mask & $king_from_mask) {
		if ($self->[CP_POS_W_KCASTLE + $to_move]
		    && ($king_side_crossing_mask & $empty)) {
			push @moves, ($king_from << 6) | $king_side_dest_shift;
		}
		if ($self->[CP_POS_W_QCASTLE + $to_move]
		    && (!(($queen_side_crossing_mask | $queen_side_rook_crossing_mask)
		         & $occupancy))) {
			push @moves, ($king_from << 6) | $queen_side_dest_shift;
		}
	}

	# Generate knight moves.
	my $knight_mask = $my_pieces & cp_pos_knights $self;
	while ($knight_mask) {
		my $from = cp_bb_count_trailing_zbits cp_bb_clear_but_least_set $knight_mask;

		$base_move = $from << 6;
	
		$target_mask = ~$my_pieces & $knight_attack_masks[$from];

		_cp_moves_from_mask $target_mask, @moves, $base_move;

		$knight_mask = cp_bb_clear_least_set $knight_mask;
	}

	# Generate bishop moves.
	my $bishop_mask = $my_pieces & cp_pos_bishops $self;
	while ($bishop_mask) {
		my $from = cp_bb_count_trailing_zbits cp_bb_clear_but_least_set $bishop_mask;

		$base_move = $from << 6;
	
		$target_mask = cp_mm_bmagic($from, $occupancy) & ($empty | $her_pieces);

		_cp_moves_from_mask $target_mask, @moves, $base_move;

		$bishop_mask = cp_bb_clear_least_set $bishop_mask;
	}

	# Generate rook moves.
	my $rook_mask = $my_pieces & cp_pos_rooks $self;
	while ($rook_mask) {
		my $from = cp_bb_count_trailing_zbits cp_bb_clear_but_least_set $rook_mask;

		$base_move = $from << 6;
	
		$target_mask = cp_mm_rmagic($from, $occupancy) & ($empty | $her_pieces);

		_cp_moves_from_mask $target_mask, @moves, $base_move;

		$rook_mask = cp_bb_clear_least_set $rook_mask;
	}

	# Generate king moves.  We take advantage of the fact that there is always
	# exactly one king of each color on the board.  So there is no need for a
	# loop.
	my $from = cp_bb_count_trailing_zbits $king_mask;

	# FIXME! 6 should be a constant!
	$base_move = $from << 6;

	$target_mask = ~$my_pieces & $king_attack_masks[$from];

	_cp_moves_from_mask $target_mask, @moves, $base_move;

	# Generate pawn moves.
	my ($regular_mask, $double_mask, $promotion_mask, $offset) =
		@{$pawn_aux_data[$to_move]};

	my ($pawn_single_masks, $pawn_double_masks, $pawn_capture_masks) = 
		@{$pawn_masks[$to_move]};

	my $pawns = cp_pos_pawns $self;

	my $pawn_mask;

	my $ep_shift = cp_pos_ep_shift $self;
	my $ep_target_mask = $ep_shift ? (1 << $ep_shift) : 0; 

	# Pawn single steps and captures w/o promotions.
	$pawn_mask = $my_pieces & $pawns & $regular_mask;
	while ($pawn_mask) {
		my $from = cp_bb_count_trailing_zbits cp_bb_clear_but_least_set $pawn_mask;

		$base_move = $from << 6;
		$target_mask = ($pawn_single_masks->[$from] & $empty)
			| ($pawn_capture_masks->[$from] & ($her_pieces | $ep_target_mask));
		_cp_moves_from_mask $target_mask, @moves, $base_move;
		$pawn_mask = cp_bb_clear_least_set $pawn_mask;
	}

	# Pawn double steps.
	$pawn_mask = $my_pieces & $pawns & $double_mask;
	while ($pawn_mask) {
		my $from = cp_bb_count_trailing_zbits cp_bb_clear_but_least_set $pawn_mask;
		my $cross_mask = $pawn_single_masks->[$from] & $empty;

		if ($cross_mask) {
			$target_mask = $pawn_double_masks->[$from] & $empty;
			if ($target_mask) {
				my $to = $from + ($offset << 1);
				push @moves, $from << 6 | $to;
			}
		}
		$pawn_mask = cp_bb_clear_least_set $pawn_mask;
	}

	return @moves;
}

sub update {
	my ($self) = @_;

	# Update king's shift.
	my $wkings = cp_pos_kings($self) & cp_pos_w_pieces($self);
	cp_pos_w_king_shift($self) = cp_bb_count_trailing_zbits($wkings);
	my $bkings = cp_pos_kings($self) & cp_pos_b_pieces($self);
	cp_pos_b_king_shift($self) = cp_bb_count_trailing_zbits($bkings);

	my $my_color = cp_pos_to_move($self);
	my $her_color = !$my_color;
	my $my_pieces = $self->[CP_POS_W_PIECES + $my_color];
	my $her_pieces = $self->[CP_POS_W_PIECES + $her_color];
	my $occupancy = $my_pieces | $her_pieces;
	my $empty = ~$occupancy;
	my $king_shift = $self->[CP_POS_W_KING_SHIFT + $my_color];
	cp_pos_in_check($self) = $her_pieces
		& (($pawn_masks[$my_color]->[2]->[$king_shift] & cp_pos_pawns($self))
		   | ($knight_attack_masks[$king_shift] & cp_pos_knights($self))
		   | (cp_mm_bmagic($king_shift, $occupancy) & cp_pos_bishops($self))
		   | (cp_mm_rmagic($king_shift, $occupancy) & cp_pos_rooks($self)));

	return $self;
}

# Class methods.
sub parseCoordinateNotation {
	# FIXME! This should be a constructor of Chess::Position::Move
	my ($self, $move) = @_;

	return if $move !~ /^([a-h][1-8])([a-h][1-8])([qrbn])?$/;

	my ($from, $to, $promote) = ($1, $2, $3);

	my $move = $self->squareToShift($from) << 6 | $self->squareToShift($to);

	if ($promote) {
		my %pieces = (
			q => CP_QUEEN,
			r => CP_ROOK,
			b => CP_BISHOP,
			n => CP_KNIGHT,
		);
		$move |= ($pieces{$promote} << 13);
	}

	return $move;
}

sub dumpBitboard {
	my (undef, $bitboard) = @_;

	my $output = "  a b c d e f g h\n";
	foreach my $shift (reverse (0 .. 63)) {
		if (($shift & 0x7) == 0x7) {
			$output .= 1 + ($shift >> 3);
		}
		if ($bitboard & 1 << $shift) {
			$output .= ' x';
		} else {
			$output .= ' .';
		}

		if (($shift & 0x7) == 0) {
			$output .= ' ';
			$output .= 1 + ($shift >> 3);
			$output .= "\n";
		}
	}
	$output .= "  a b c d e f g h\n";


	return $output;
}

sub coordinatesToShift {
	my (undef, $file, $rank) = @_;

	return $rank * 8 + 7 - $file;
}

sub shiftToCoordinates {
	my (undef, $shift) = @_;

	my $file = (7 - $shift) & 0x7;
	my $rank = $shift >> 3;

	return $file, $rank;
}

sub shiftToSquare {
	my (undef, $shift) = @_;

	my $rank = 1 + ($shift >> 3);
	my $file = 7 - ($shift & 0x7);

	return sprintf '%c%u ', $file + ord 'a', $rank;
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

###########################################################################
# Generate attack masks.
###########################################################################

# This would be slightly more efficient in one giant loop but with separate
# loops for each variable, it is easier to understand and maintain.

# King attack masks.
for my $shift (0 .. 63) {
	my ($file, $rank) = shiftToCoordinates undef, $shift;

	my $mask = 0;

	# East.
	$mask |= (1 << ($shift - 1)) if $file < 7;

	# South-east.
	$mask |= (1 << ($shift - 9)) if $file < 7 && $rank > 0;

	# South.
	$mask |= (1 << ($shift - 8)) if              $rank > 0;

	# South-west.
	$mask |= (1 << ($shift - 7)) if $file > 0 && $rank > 0;

	# West.
	$mask |= (1 << ($shift + 1)) if $file > 0;

	# North-west.
	$mask |= (1 << ($shift + 9)) if $file > 0 && $rank < 7;

	# North.
	$mask |= (1 << ($shift + 8)) if              $rank < 7;

	# North-east.
	$mask |= (1 << ($shift + 7)) if $file < 7 && $rank < 7;

	$king_attack_masks[$shift] = $mask;
}

# Knight attack masks.
for my $shift (0 .. 63) {
	my ($file, $rank) = shiftToCoordinates undef, $shift;

	my $mask = 0;

	# North-north-east.
	$mask |= (1 << ($shift + 15)) if $file < 7 && $rank < 6;

	# North-east-east.
	$mask |= (1 << ($shift +  6)) if $file < 6 && $rank < 7;

	# South-east-east.
	$mask |= (1 << ($shift - 10)) if $file < 6 && $rank > 0;

	# South-south-east.
	$mask |= (1 << ($shift - 17)) if $file < 7&&  $rank > 1;

	# South-south-west.
	$mask |= (1 << ($shift - 15)) if $file > 0 && $rank > 1;

	# South-west-west.
	$mask |= (1 << ($shift -  6)) if $file > 1 && $rank > 0;

	# North-west-west.
	$mask |= (1 << ($shift + 10)) if $file > 1 && $rank < 7;

	# North-north-west.
	$mask |= (1 << ($shift + 17)) if $file > 0 && $rank < 6;

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
		$mask |= 1 << ($shift + 9);
	}
	if ($file < 7) {
		$mask |= 1 << ($shift + 7);
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
		$mask |= 1 << ($shift - 7);
	}
	if ($file < 7) {
		$mask |= 1 << ($shift - 9);
	}
	push @black_pawn_capture_masks, $mask;
}
$pawn_masks[CP_BLACK] = [\@black_pawn_single_masks, \@black_pawn_double_masks,
		\@black_pawn_capture_masks];

# Magic moves.
sub initmagicmoves_occ {
	my ($squares, $linocc) = @_;

	my $ret = 0;
	for (my $i = 0; $i < @$squares; ++$i) {
		if ($linocc & (1 << $i)) {
			$ret |= (1 << $squares->[$i]);
		}
	}

	return $ret;
}

sub initmagicmoves_Rmoves {
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

sub initmagicmoves_Bmoves {
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
my @initmagicmoves_bitpos64_database = (
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
		$squares[$numsquares++] = $initmagicmoves_bitpos64_database[$mask58 & (($bit * 0x07EDD5E59A4E28C2) >> 58)];
		$temp ^= $bit;
	}
	for ($temp = 0; $temp < (1 << $numsquares); ++$temp) {
		my $tempocc = initmagicmoves_occ(\@squares, $temp);
		my $j = (($tempocc) * $magicmoves_b_magics[$i]);
		my $k = ($j >> MINIMAL_B_BITS_SHIFT) & $b_bits_shift_mask;
		$magicmovesbdb[$i]->[$k]
				= initmagicmoves_Bmoves($i, $tempocc);
	}
}

for (my $i = 0; $i < 64; ++$i) {
	my @squares;
	my $numsquares = 0;
	my $temp = $magicmoves_r_mask[$i];
	while ($temp) {
			my $bit = $temp & -$temp;
			$squares[$numsquares++] = $initmagicmoves_bitpos64_database[$mask58 & (($bit * 0x07EDD5E59A4E28C2) >> 58)];
			$temp ^= $bit;
	}
	for ($temp = 0; $temp < 1 << $numsquares; ++$temp) {
		my $tempocc = initmagicmoves_occ(\@squares, $temp);

		my $j = (($tempocc) * $magicmoves_r_magics[$i]);
		my $k = ($j >> MINIMAL_R_BITS_SHIFT) & $r_bits_shift_mask;
		$magicmovesrdb[$i][$k] = initmagicmoves_Rmoves($i, $tempocc);
	}
}

1;
