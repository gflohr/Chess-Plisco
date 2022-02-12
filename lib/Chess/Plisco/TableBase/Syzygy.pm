#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# This file is heavily inspired by the source code of Fathom, see
# https://github.com/jdart1/Fathom which is a fork of
# https://github.com/basil00/Fathom.

# Original calling hierarchy in fathom.c:
#
# main() // fathom.c
# -> tb_probe_root() // tbprobe.h (inline)
#    -> tb_probe_root_impl() // tbprobe.c
#       -> probe_root() // tbprobe.c
#
# Our calling hierarchy:
#
# core::
# -> probeRoot()
#    # -> omitted.
#       -> __probeRoot()

package Chess::Plisco::TableBase::Syzygy;

use strict;
use integer;

use Scalar::Util qw(reftype);
use Locale::TextDomain qw('Chess-Plisco');
use File::Spec;

use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

use base qw(Exporter);

our @EXPORT = qw(
	TB_LOSS
	TB_BLESSED_LOSS
	TB_DRAW
	TB_CURSED_WIN
	TB_WIN
	TB_RESULT_FAILED

	TB_MOVE_NONE
	TB_MOVE_STALEMATE
	TB_MOVE_CHECKMATE
);

use constant TB_LOSS => 0;
use constant TB_BLESSED_LOSS => 1;
use constant TB_DRAW => 2;
use constant TB_CURSED_WIN => 3;
use constant TB_WIN => 4;

use constant TB_PATHS => 4;
use constant TB_RESULT_WDL_MASK => 0x0000000F;
use constant TB_RESULT_TO_MASK => 0x000003F0;
use constant TB_RESULT_FROM_MASK => 0x0000FC00;
use constant TB_RESULT_PROMOTES_MASK => 0x00070000;
use constant TB_RESULT_EP_MASK => 0x00080000;
use constant TB_RESULT_DTZ_MASK => 0xFFF00000;
use constant TB_RESULT_WDL_SHIFT => 0;
use constant TB_RESULT_TO_SHIFT => 4;
use constant TB_RESULT_FROM_SHIFT => 10;
use constant TB_RESULT_PROMOTES_SHIFT => 16;
use constant TB_RESULT_EP_SHIFT => 19;
use constant TB_RESULT_DTZ_SHIFT => 20;

use constant TB_RESULT_FAILED => 0xffffffff;
# Without the parentheses around the constant, Visual Studio Code's syntax
# highlighting gets messed up.
use constant TB_RESULT_CHECKMATE =>
	((TB_WIN << (TB_RESULT_WDL_SHIFT)) & TB_RESULT_WDL_MASK);
use constant TB_RESULT_STALEMATE =>
	((TB_DRAW << (TB_RESULT_WDL_SHIFT)) & TB_RESULT_WDL_MASK) ;

use constant TB_MOVE_NONE => 0;
use constant TB_MOVE_STALEMATE => 0xffff;
use constant TB_MOVE_CHECKMATE => 0xfffe;

use constant BEST_NONE => 0xffff;
use constant SCORE_ILLEGAL => 0x7fff;

# Indices into the object.
use constant TB_LARGEST => 0;
use constant TB_BINOMIAL => 1;
use constant TB_PAWN_IDX => 2;
use constant TB_PAWN_FACTOR_FILE => 3;
use constant TB_PAWN_FACTOR_RANK => 4;
use constant TB_MAX_CARDINALITY => 5;
use constant TB_MAX_CARDINALITY_DTM => 6;
use constant TB_PAWN_ENTRY => 7;
use constant TB_PIECE_ENTRY => 8;
use constant TB_HASH => 9;

use constant SEP_CHAR => ($^O =~ /win32/i) ? ';' : ':';

use constant TB_PIECES => 7;
use constant TB_HASHBITS => 12;
use constant TB_HASHSIZE => 1 << (TB_HASHBITS);
use constant TB_HASHMASK => (1 << (TB_HASHBITS)) - 1;
use constant TB_MAX_PIECE => 650;
use constant TB_MAX_PAWN => 861;
use constant TB_MAX_SYMS => 4096;

use constant TB_PAWN => 1;
use constant TB_KNIGHT => 2;
use constant TB_BISHOP => 3;
use constant TB_ROOK => 4;
use constant TB_QUEEN => 5;
use constant TB_KING => 6;

use constant TB_WPAWN => TB_PAWN;
use constant TB_BPAWN => (TB_PAWN | 8);

use constant WHITE_KING => (TB_WPAWN + 5);
use constant WHITE_QUEEN => (TB_WPAWN + 4);
use constant WHITE_ROOK => (TB_WPAWN + 3);
use constant WHITE_BISHOP => (TB_WPAWN + 2);
use constant WHITE_KNIGHT => (TB_WPAWN + 1);
use constant WHITE_PAWN => TB_WPAWN;
use constant BLACK_KING => (TB_BPAWN + 5);
use constant BLACK_QUEEN => (TB_BPAWN + 4);
use constant BLACK_ROOK => (TB_BPAWN + 3);
use constant BLACK_BISHOP => (TB_BPAWN + 2);
use constant BLACK_KNIGHT => (TB_BPAWN + 1);
use constant BLACK_PAWN => TB_BPAWN;

use constant PRIME_WHITE_QUEEN => 11811845319353239651;
use constant PRIME_WHITE_ROOK => 10979190538029446137;
use constant PRIME_WHITE_BISHOP => 12311744257139811149;
use constant PRIME_WHITE_KNIGHT => 15202887380319082783;
use constant PRIME_WHITE_PAWN => 17008651141875982339;
use constant PRIME_BLACK_QUEEN => 15484752644942473553;
use constant PRIME_BLACK_ROOK => 18264461213049635989;
use constant PRIME_BLACK_BISHOP => 15394650811035483107;
use constant PRIME_BLACK_KNIGHT => 13469005675588064321;
use constant PRIME_BLACK_PAWN => 11695583624105689831;

my @off_diag = (
	0,-1,-1,-1,-1,-1,-1,-1,
	1, 0,-1,-1,-1,-1,-1,-1,
	1, 1, 0,-1,-1,-1,-1,-1,
	1, 1, 1, 0,-1,-1,-1,-1,
	1, 1, 1, 1, 0,-1,-1,-1,
	1, 1, 1, 1, 1, 0,-1,-1,
	1, 1, 1, 1, 1, 1, 0,-1,
	1, 1, 1, 1, 1, 1, 1, 0
);

my @triangle = (
	6, 0, 1, 2, 2, 1, 0, 6,
	0, 7, 3, 4, 4, 3, 7, 0,
	1, 3, 8, 5, 5, 8, 3, 1,
	2, 4, 5, 9, 9, 5, 4, 2,
	2, 4, 5, 9, 9, 5, 4, 2,
	1, 3, 8, 5, 5, 8, 3, 1,
	0, 7, 3, 4, 4, 3, 7, 0,
	6, 0, 1, 2, 2, 1, 0, 6
);

my @flip_diag = (
	0,  8, 16, 24, 32, 40, 48, 56,
	1,  9, 17, 25, 33, 41, 49, 57,
	2, 10, 18, 26, 34, 42, 50, 58,
	3, 11, 19, 27, 35, 43, 51, 59,
	4, 12, 20, 28, 36, 44, 52, 60,
	5, 13, 21, 29, 37, 45, 53, 61,
	6, 14, 22, 30, 38, 46, 54, 62,
	7, 15, 23, 31, 39, 47, 55, 63
);

my @lower = (
	28,  0,  1,  2,  3,  4,  5,  6,
	 0, 29,  7,  8,  9, 10, 11, 12,
	 1,  7, 30, 13, 14, 15, 16, 17,
	 2,  8, 13, 31, 18, 19, 20, 21,
	 3,  9, 14, 18, 32, 22, 23, 24,
	 4, 10, 15, 19, 22, 33, 25, 26,
	 5, 11, 16, 20, 23, 25, 34, 27,
	 6, 12, 17, 21, 24, 26, 27, 35
);

my @diag = (
	 0,  0,  0,  0,  0,  0,  0,  8,
	 0,  1,  0,  0,  0,  0,  9,  0,
	 0,  0,  2,  0,  0, 10,  0,  0,
	 0,  0,  0,  3, 11,  0,  0,  0,
	 0,  0,  0, 12,  4,  0,  0,  0,
	 0,  0, 13,  0,  0,  5,  0,  0,
	 0, 14,  0,  0,  0,  0,  6,  0,
	15,  0,  0,  0,  0,  0,  0,  7
);

my @flap = (
	[
		0,  0,  0,  0,  0,  0,  0,  0,
		0,  6, 12, 18, 18, 12,  6,  0,
		1,  7, 13, 19, 19, 13,  7,  1,
		2,  8, 14, 20, 20, 14,  8,  2,
		3,  9, 15, 21, 21, 15,  9,  3,
		4, 10, 16, 22, 22, 16, 10,  4,
		5, 11, 17, 23, 23, 17, 11,  5,
		0,  0,  0,  0,  0,  0,  0,  0
	],
	[
		 0,  0,  0,  0,  0,  0,  0,  0,
		 0,  1,  2,  3,  3,  2,  1,  0,
		 4,  5,  6,  7,  7,  6,  5,  4,
		 8,  9, 10, 11, 11, 10,  9,  8,
		12, 13, 14, 15, 15, 14, 13, 12,
		16, 17, 18, 19, 19, 18, 17, 16,
		20, 21, 22, 23, 23, 22, 21, 20,
		 0,  0,  0,  0,  0,  0,  0,  0
	],
);

my @pawn_twist = (
	[
		 0,  0,  0,  0,  0,  0,  0,  0,
		47, 35, 23, 11, 10, 22, 34, 46,
		45, 33, 21,  9,  8, 20, 32, 44,
		43, 31, 19,  7,  6, 18, 30, 42,
		41, 29, 17,  5,  4, 16, 28, 40,
		39, 27, 15,  3,  2, 14, 26, 38,
		37, 25, 13,  1,  0, 12, 24, 36,
		 0,  0,  0,  0,  0,  0,  0,  0
	],
	[
		 0,  0,  0,  0,  0,  0,  0,  0,
		47, 45, 43, 41, 40, 42, 44, 46,
		39, 37, 35, 33, 32, 34, 36, 38,
		31, 29, 27, 25, 24, 26, 28, 30,
		23, 21, 19, 17, 16, 18, 20, 22,
		15, 13, 11,  9,  8, 10, 12, 14,
		 7,  5,  3,  1,  0,  2,  4,  6,
		 0,  0,  0,  0,  0,  0,  0,  0
	],
);

my @kk_idx = (
	[
		-1, -1, -1,  0,  1,  2,  3,  4,
		-1, -1, -1,  5,  6,  7,  8,  9,
		10, 11, 12, 13, 14, 15, 16, 17,
		18, 19, 20, 21, 22, 23, 24, 25,
		26, 27, 28, 29, 30, 31, 32, 33,
		34, 35, 36, 37, 38, 39, 40, 41,
		42, 43, 44, 45, 46, 47, 48, 49,
		50, 51, 52, 53, 54, 55, 56, 57
	],
	[
		 58, -1, -1, -1, 59, 60, 61, 62,
		 63, -1, -1, -1, 64, 65, 66, 67,
		 68, 69, 70, 71, 72, 73, 74, 75,
		 76, 77, 78, 79, 80, 81, 82, 83,
		 84, 85, 86, 87, 88, 89, 90, 91,
		 92, 93, 94, 95, 96, 97, 98, 99,
		100,101,102,103,104,105,106,107,
		108,109,110,111,112,113,114,115
	],
	[
		116,117, -1, -1, -1,118,119,120,
		121,122, -1, -1, -1,123,124,125,
		126,127,128,129,130,131,132,133,
		134,135,136,137,138,139,140,141,
		142,143,144,145,146,147,148,149,
		150,151,152,153,154,155,156,157,
		158,159,160,161,162,163,164,165,
		166,167,168,169,170,171,172,173
	],
	[
		174, -1, -1, -1,175,176,177,178,
		179, -1, -1, -1,180,181,182,183,
		184, -1, -1, -1,185,186,187,188,
		189,190,191,192,193,194,195,196,
		197,198,199,200,201,202,203,204,
		205,206,207,208,209,210,211,212,
		213,214,215,216,217,218,219,220,
		221,222,223,224,225,226,227,228
	],
	[
		229,230, -1, -1, -1,231,232,233,
		234,235, -1, -1, -1,236,237,238,
		239,240, -1, -1, -1,241,242,243,
		244,245,246,247,248,249,250,251,
		252,253,254,255,256,257,258,259,
		260,261,262,263,264,265,266,267,
		268,269,270,271,272,273,274,275,
		276,277,278,279,280,281,282,283
	],
	[
		284,285,286,287,288,289,290,291,
		292,293, -1, -1, -1,294,295,296,
		297,298, -1, -1, -1,299,300,301,
		302,303, -1, -1, -1,304,305,306,
		307,308,309,310,311,312,313,314,
		315,316,317,318,319,320,321,322,
		323,324,325,326,327,328,329,330,
		331,332,333,334,335,336,337,338
	],
	[
		-1, -1,339,340,341,342,343,344,
		-1, -1,345,346,347,348,349,350,
		-1, -1,441,351,352,353,354,355,
		-1, -1, -1,442,356,357,358,359,
		-1, -1, -1, -1,443,360,361,362,
		-1, -1, -1, -1, -1,444,363,364,
		-1, -1, -1, -1, -1, -1,445,365,
		-1, -1, -1, -1, -1, -1, -1,446
	],
	[
		-1, -1, -1,366,367,368,369,370,
		-1, -1, -1,371,372,373,374,375,
		-1, -1, -1,376,377,378,379,380,
		-1, -1, -1,447,381,382,383,384,
		-1, -1, -1, -1,448,385,386,387,
		-1, -1, -1, -1, -1,449,388,389,
		-1, -1, -1, -1, -1, -1,450,390,
		-1, -1, -1, -1, -1, -1, -1,451
	],
	[
		452,391,392,393,394,395,396,397,
		 -1, -1, -1, -1,398,399,400,401,
		 -1, -1, -1, -1,402,403,404,405,
		 -1, -1, -1, -1,406,407,408,409,
		 -1, -1, -1, -1,453,410,411,412,
		 -1, -1, -1, -1, -1,454,413,414,
		 -1, -1, -1, -1, -1, -1,455,415,
		 -1, -1, -1, -1, -1, -1, -1,456
	],
	[
		457,416,417,418,419,420,421,422,
		 -1,458,423,424,425,426,427,428,
		 -1, -1, -1, -1, -1,429,430,431,
		 -1, -1, -1, -1, -1,432,433,434,
		 -1, -1, -1, -1, -1,435,436,437,
		 -1, -1, -1, -1, -1,459,438,439,
		 -1, -1, -1, -1, -1, -1,460,440,
		 -1, -1, -1, -1, -1, -1, -1,461
	],
);

my @char_to_piece_type;
my $piece = CP_NO_PIECE - 1;
foreach my $c (@{CP_PIECE_CHARS->[0]}) {
	++$piece;
	next if !$c;
	$char_to_piece_type[ord $c] = $piece;
}

my @WdlToDtz = [ -1, -101, 0, 101, 1];

use constant WDL => 0;
use constant DTM => 1;
use constant DTZ => 2;

use constant TB_SUFFIX => ['.rtbw', '.rtbm', '.rtbz'];
use constant TB_MAGIC => [0x5d23e871, 0x88ac504b, 0xa50c66d7];

use constant PIECE_ENC => 0;
use constant FILE_ENC => 1;
use constant RANK_ENC => 2;

sub new {
	my ($class, $path) = @_;

	my $self = bless [], $class;

	$self->__initIndices($path);

	return $self;
}

sub largest {
	shift->[TB_LARGEST];
}

sub __dtzToWdl {
	my ($self, $cnt50, $dtz) = @_;

	my $wdl = 0;
	if ($dtz > 0) {
		$wdl = ($dtz + $cnt50 <= 100? 2: 1);
	} elsif ($dtz < 0) {
		$wdl = (-$dtz + $cnt50 <= 100? -2: -1);
	}
	
	return $wdl + 2;
}

# This is probe_root() in Fathom.
sub __probeRoot {
	my ($self, $position, $score, $results, $moves) = @_;

	my $success;
	my $dtz = $self->__probeDTZ($position, \$success, $moves);
	if (!$success) {
		return 0;
	}

	my @scores;
	my $num_draw = 0;
	my $i = 0;
	my $pos_info = $position->[CP_POS_INFO];
	foreach my $move (@$moves) {
		my $pos1 = $position->copy;
		$pos1->doMove($move);
		# Move cannot be illegal.
		my $v = 0;
		if ($dtz > 0 && cp_pos_in_check($pos1) && !$pos1->legalMoves) {
			$v = 1;
		} else {
			if (cp_pos_half_move_clock($pos1) != 0) {
				$v = $self->__probeDTZ($pos1, $success);
				if ($v > 0) {
					++$v;
				} elsif ($v < 0) {
					--$v;
				}
			} else {
				$v = $self->__probeWDL($pos1, $success);
				$v = $WdlToDtz[$v + 2];
			}
		}

		$num_draw += ($v == 0);
		if (!$success) {
			return 0;
		}
		$scores[$i] = $v;

		if ($results) {
			my $ep_shift = cp_pos_en_passant_shift($position);
			my $res = 0;
			my $is_ep = $ep_shift && ($ep_shift == cp_move_to($move))
				&& cp_move_captured($move) == CP_PAWN;
			my $rule50 = cp_pos_half_move_clock($position);
			$results->[$i] = 
				($self->__dtzToWdl($rule50, $dtz) << (TB_RESULT_WDL_SHIFT) & TB_RESULT_WDL_MASK)
				| (($dtz < 0? -$dtz: $dtz) << (TB_RESULT_DTZ_SHIFT) & TB_RESULT_DTZ_MASK)
				| ((cp_move_from($move)) << (TB_RESULT_FROM_SHIFT) & TB_RESULT_FROM_MASK)
				| ((cp_move_to($move)) << (TB_RESULT_TO_SHIFT) & TB_RESULT_TO_MASK)
				| ((cp_move_promote($move)) << (TB_RESULT_PROMOTES_SHIFT) & TB_RESULT_PROMOTES_MASK)
				| (($is_ep << (TB_RESULT_EP_SHIFT)) & TB_RESULT_EP_MASK)
				;
		}

		++$i;
	}

	if ($results) {
		push @$results, TB_RESULT_FAILED;
	}
	if ($score) {
		$$score = $dtz;
	}

	if ($dtz > 0) {   
		my $best = BEST_NONE;
		my $best_move = 0;
		for (my $i = 0; $i < @$moves; ++$i) {
			my $v = $scores[$i];
			if ($v == SCORE_ILLEGAL) {
				next;
			}
			if ($v > 0 && $v < $best) {
				$best = $v;
				$best_move = $moves->[$i];
			}
		}
		return ($best == BEST_NONE ? 0 : $best_move);
	} elsif ($dtz < 0) {
		my $best = 0;
		my $best_move = 0;
		for (my $i = 0; $i < @$moves; ++$i) {
			my $v = $scores[$i];
			if ($v == SCORE_ILLEGAL) {
				next;
			}
			if ($v < $best) {
				$best = $v;
				$best_move = $moves->[$i];
			}
		}
		return ($best == 0 ? TB_MOVE_CHECKMATE: $best_move);
	} else {
		if ($num_draw == 0) {
			return TB_MOVE_STALEMATE;
		}

		my $count = $self->__calcKey($position, !cp_pos_info_to_move($pos_info)) % $num_draw;
		for (my $i = 0; $i < @$moves; ++$i) {
			my $v = $scores[$i];
			if ($v == SCORE_ILLEGAL) {
				next;
			}
			if ($v == 0) {
				if ($count == 0) {
					return $moves->[$i];
				}
				--$count;
			}
		}

		return 0;
	}
}

sub __probeDTZ {
	my ($self, $position, $success, $moves) = @_;

	my $wdl = $self->__probeWDL($position, $success, $moves);
	if (!$success) {
		return TB_MOVE_NONE;
	}

	if ($wdl == 0) {
		return TB_MOVE_NONE;
	}

	if ($$success == 2) {
		return $WdlToDtz[$wdl + 2];
	}

	if ($wdl > 0) {
		foreach my $move (@$moves) {
			if (cp_move_captured($move) || cp_move_piece($move) != CP_PAWN) {
				next;
			}
			my $pos1 = $position->copy;
			$pos1->doMove($move);
			my $v = -$self->__probeWDL($position, $success);
			if ($$success == 0) {
				return TB_MOVE_NONE;
			}
			if ($v == $wdl) {
				return $WdlToDtz[$wdl + 2];
			}
		}
	}

	my $dtz = $self->__probeDTZTable($position, $wdl, $success, $moves);
	if ($$success >= 0) {
		return $WdlToDtz[$wdl + 2] + (($wdl > 0) ? $dtz : -$dtz);
	}

	my $best;
	if ($wdl > 0) {
		$wdl = 0x7fff_ffff;
	} else {
		$best = $WdlToDtz[$wdl + 2];
	}

	foreach my $move (@$moves) {
		if (cp_move_captured($move) || cp_move_piece($move) == CP_PAWN) {
			next;
		}
		my $state = $position->doMove($move);
		my $pos1 = $position->copy;
		my $v = -$self->probeDTZ($pos1, $success);
		$position->undoMove($state);

		if ($v == 1 && cp_pos_in_check($pos1) && !$pos1->legalMoves) {
			$best = 1;
		} elsif ($wdl > 0) {
			if ($v > 0 && $v + 1 < $best) {
				$best = $v + 1;
			}
		} else {
			if ($v - 1 < $best) {
				$best = $v - 1;
			}
		}

		if ($$success == 0) {
			return TB_MOVE_NONE;
		}
	}

	return $best;
}

sub __probeTable {
	my ($self, $pos, $s, $success, $type) = @_;

	my $key = $self->__calcKey($pos, 0);

	# Check for KvK.
	if ($type == WDL && $key == 0) {
		return 0;
	}

	my $tb_hash = $self->[TB_HASH];
	my $hash_idx = $key >> (64 - TB_HASHBITS);
	while ($tb_hash->[$hash_idx]->{key} && $tb_hash->[$hash_idx]->{$key} != $key) {
		$hash_idx = ($hash_idx + 1) & ((1 << (TB_HASHBITS)) - 1);
	}
	if (!$tb_hash->[$hash_idx]->{ptr}) {
		$$success = 0;
		return 0;
	}

	my $be = $tb_hash->[$hash_idx]->{ptr};
	if (($type == DTM && !$be->{has_dtm}) || ($type == DTZ && !$be->{has_dtz})) {
		$$success = 0;
		return 0;
	}

	if (!$be->{ready}->[$type]) {
		my $str = $self->__prtStr($pos, $be->{key} != $key);
		if ($self->__initTable($be, $str, $type)) {
			undef $tb_hash->[$hash_idx]->{ptr};
			$$success = 0;
			return 0;
		}
		$be->{ready}->[$type] = 1;
	}

	my ($bside, $flip);
	if (!$be->{symmetric}) {
		$flip = $key != $be->{key};
		$bside = (pos->turn == WHITE) == flip;
    if (type == DTM && be->hasPawns && PAWN(be)->dtmSwitched) {
      flip = !flip;
      bside = !bside;
    }
  } else {
    flip = pos->turn != WHITE;
    bside = false;
  }

die;
}

sub __probeWDLTable {
	my ($self, $position, $success, $moves) = @_;

	return $self->__probeTable($position, 0, $success, WDL, $moves);
}

sub __probeDTMTable {
	my ($self, $position, $won, $success, $moves) = @_;

	return $self->__probeTable($position, $won, $success, DTM, $moves);
}

sub __probeDTZTable {
	my ($self, $position, $wdl, $success, $moves) = @_;

	return $self->__probeTable($position, $wdl, $success, DTZ, $moves);
}

# __BEGIN_MACROS__

# Moves MUST be fully expanded moves with capture information.
# This is tb_probe_root_impl in Fathom.
sub probeRoot {
	my ($self, $position, $moves) = @_;

	if (!@$moves) {
		if ($position->[CP_POS_IN_CHECK]) {
			return TB_RESULT_CHECKMATE;
		} else {
			return TB_RESULT_STALEMATE;
		}
	}

	my $pos_info = cp_pos_info $position;
	if (cp_pos_info_castling_rights $pos_info) {
		return TB_RESULT_FAILED;
	}

	my $rule50 = cp_pos_half_move_clock $position;
	my $ep_shift = cp_pos_info_en_passant_shift $pos_info;
	my $turn = cp_pos_info_to_move $pos_info;

	my $dtz;
	my @results;
	my $move = $self->__probeRoot($position, \$dtz, \@results, $moves);
	if ($move == TB_MOVE_NONE) {
		return TB_RESULT_FAILED;
	}
	if ($move == TB_MOVE_CHECKMATE) {
		return TB_RESULT_CHECKMATE;
	}
	if ($move == TB_MOVE_STALEMATE) {
		return TB_RESULT_STALEMATE;
	}

	my $res = 0;
	my $is_ep = $ep_shift && ($ep_shift == cp_move_to($move))
		&& cp_move_captured($move) == CP_PAWN;
	$res =
		($self->__dtzToWdl($rule50, $dtz) << (TB_RESULT_WDL_SHIFT) & TB_RESULT_WDL_MASK)
		| (($dtz < 0? -$dtz: $dtz) << (TB_RESULT_DTZ_SHIFT) & TB_RESULT_DTZ_MASK)
		| ((cp_move_from($move)) << (TB_RESULT_FROM_SHIFT) & TB_RESULT_FROM_MASK)
		| ((cp_move_to($move)) << (TB_RESULT_TO_SHIFT) & TB_RESULT_TO_MASK)
		| ((cp_move_promote($move)) << (TB_RESULT_PROMOTES_SHIFT) & TB_RESULT_PROMOTES_MASK)
		| (($is_ep << (TB_RESULT_EP_SHIFT)) & TB_RESULT_EP_MASK)
		;
	return $res;
}

sub __probeWDL {
	my ($self, $position, $success, $moves) = @_;

	$$success = 1;
	$moves ||= $position->legalMoves;

	my $pos_info = $position->[CP_POS_INFO];
	my $ep_shift = cp_pos_info_en_passant_shift $pos_info;

	my ($best_cap, $best_ep) = (-3, -3);
	foreach my $move (@$moves) {
		if (!cp_move_capture_or_promotion($move)) {
			next;
		}

		my $val = -$self->__probeAlphaBeta($position, -2, -$best_cap, $success,
				$moves);
		if ($$success == 0) {
			return 0;
		}
		if ($val > $best_cap) {
			if ($val == 2) {
				$$success = 2;
				return 2;
			}

			# Is this an en passant capture?
			if ($ep_shift && cp_move_to($move) == $ep_shift) {
				$best_ep = $val;
			} else {
				$best_cap = $val;
			}
		}
	}

	my $val = $self->__probeWDLTable($position, $success, $moves);
	if ($$success == 0) {
		return 0;
	}

	if ($best_ep > $best_cap) {
		if ($best_ep > $val) {
			$$success = 2;
			return $best_ep;
		}
		$best_cap = $best_ep;
	}

	# FIXME! We can only ge to the return here, if not in check. So that should
	# be tested in the outer if.
	if ($best_ep > -3 && $val == 0) {
		my $legal;
		foreach my $move (@$moves) {
			if (!$ep_shift || $ep_shift != cp_move_to($move)) {
				$legal = 1;
				last;
			}
		}

		if (!$legal && !$position->[CP_POS_IN_CHECK]) {
			$$success = 2;
			return $best_ep;
		}
	}

	return $val;
}

sub __probeAlphaBeta {
	my ($self, $pos, $alpha, $beta, $success, $moves) = @_;

	if (!$moves) {
		my @moves;
		foreach my $move ($pos->generatePseudoLegalAttacks) {
			my $copy = $pos->copy;
			my $status = $copy->doMove($move) or next;
			push @moves, $status->[0];
		}
		$moves = \@moves;
	}
	foreach my $move (@$moves) {
		my $val = -$self->__probeAlphaBeta($pos, -$beta, -$alpha,
				$success);
		if ($$success == 0) {
			return 0;
		}

		if ($val > $alpha) {
			if ($val >= $beta) {
				return $val;
			}
			$alpha = $val;
		}
	}

	my $val = $self->__probleWDLTable($pos, $success, $moves);
	return $alpha >= $val ? $alpha : $val;
}

sub __prtStr {
	my ($self, $pos, $flip) = @_;

	my ($white, $black) = ($pos->[CP_POS_WHITE_PIECES], $pos->[CP_POS_BLACK_PIECES]);
	my ($my_pieces, $her_pieces) = $flip ? ($black, $white) : ($white, $black);
	my ($str1, $str2) = ('K', 'vK');
	my $piece_chars = CP_PIECE_CHARS->[CP_WHITE];
	my @pieces = (CP_QUEEN, CP_ROOK, CP_BISHOP, CP_KNIGHT, CP_PAWN);
	foreach my $piece (@pieces) {
		my $pieces = $pos->[$piece];
		my $c = $piece_chars->[$piece];
		my $popcount;
		cp_bitboard_popcount($my_pieces & $pieces, $popcount);
		$str1 .= $c x $popcount;
		cp_bitboard_popcount($her_pieces & $pieces, $popcount);
		$str2 .= $c x $popcount;
	}

	return join '', $str1, $str2;
}

sub __calcKey {
	my ($self, $pos, $mirror) = @_;

	my ($pawns, $knights, $bishops, $rooks, $queens, undef, $white, $black)
		= @$pos[CP_POS_PAWNS .. CP_POS_BLACK_PIECES];
	if ($mirror) {
		($white, $black) = ($black, $white);
	}

	my $key = 0;
	my $popcount = 0;

	cp_bitboard_popcount($queens & $white, $popcount);
	$key += $popcount * PRIME_WHITE_QUEEN;
	cp_bitboard_popcount($rooks & $white, $popcount);
	$key += $popcount * PRIME_WHITE_ROOK;
	cp_bitboard_popcount($bishops & $white, $popcount);
	$key += $popcount * PRIME_WHITE_BISHOP;
	cp_bitboard_popcount($knights & $white, $popcount);
	$key += $popcount * PRIME_WHITE_KNIGHT;
	cp_bitboard_popcount($pawns & $white, $popcount);
	$key += $popcount * PRIME_WHITE_PAWN;

	cp_bitboard_popcount($queens & $black, $popcount);
	$key += $popcount * PRIME_BLACK_QUEEN;
	cp_bitboard_popcount($rooks & $black, $popcount);
	$key += $popcount * PRIME_BLACK_ROOK;
	cp_bitboard_popcount($bishops & $black, $popcount);
	$key += $popcount * PRIME_BLACK_BISHOP;
	cp_bitboard_popcount($knights & $black, $popcount);
	$key += $popcount * PRIME_BLACK_KNIGHT;
	cp_bitboard_popcount($pawns & $black, $popcount);
	$key += $popcount * PRIME_BLACK_PAWN;

	return $key;
}
# __END_MACROS__

sub __initIndices {
	my ($self, $path) = @_;

	$self->[TB_LARGEST] = 0;

	my $binomial = $self->[TB_BINOMIAL] = [
		[], [], [], [], [], []
	];
	foreach my $piece (CP_NO_PIECE, CP_PAWN, CP_BISHOP, CP_KNIGHT, CP_ROOK,
	           CP_QUEEN, CP_KING) {
		foreach my $shift (CP_A1 .. CP_H8) {
			my $f = 1;
			my $l = 1;
			for (my $k = 0; $k < $piece; ++$k) {
				$f *= ($shift - $k);
				$l *= ($k + 1);
			}
			$binomial->[$piece]->[$shift] = $f / $l;
		}
	}

	my $pawn_idx = $self->[TB_PAWN_IDX] = [
		[[], [], [], [], [], []],
		[[], [], [], [], [], []],
	];
	my $pawn_factor_file = $self->[TB_PAWN_FACTOR_FILE] = [
		[[], [], [], [], [], []],
		[[], [], [], [], [], []],
	];
	my $pawn_factor_rank = $self->[TB_PAWN_FACTOR_RANK] = [
		[[], [], [], [], [], []],
		[[], [], [], [], [], []],
	];
	foreach my $i (0 .. 5) {
		my $s = 0;
		foreach my $j (0 .. 23) {
			$pawn_idx->[0]->[$i]->[$j] = $s;
			$s += $binomial->[$i]->[$pawn_twist[0]->[(1 + ($j % 6)) * 8 + ($j / 6)]];
			if (($j + 1) % 6 == 0) {
				$pawn_factor_file->[$i]->[$j / 6] = $s;
				$s = 0;
			}
		}
	}

	foreach my $i (0 .. 5) {
		my $s = 0;
		for (my $j = 0; $j < 24; ++$j) {
			$pawn_idx->[1]->[$i]->[$j] = $s;
			$s += $binomial->[$i]->[$pawn_twist[1]->[(1 + ($j / 4)) * 8 + ($j % 4)]];
			if (($j + 1) % 4 == 0) {
				$pawn_factor_rank->[$i]->[$j / 4] = $s;
				$s = 0;
			}
		}
	}

	return 1 if '' eq $path || '<empty>' eq $path;

	my $paths = $self->[TB_PATHS] = [split SEP_CHAR, $path];

	my ($tb_num_pieces, $tb_num_pawns) = (0, 0);
	$self->[TB_MAX_CARDINALITY] = 0;
	$self->[TB_MAX_CARDINALITY_DTM] = 0;
	
	# FIXME! Does this have to be per-instance?
	my @tb_hash;
	for (my $i = 0; $i < TB_HASHSIZE; ++$i) {
		$tb_hash[$i] = {
			key => 0,
			ptr => 0,
		};
	}
	$self->[TB_HASH] = \@tb_hash;

	$self->[TB_PAWN_ENTRY] = [];
	$self->[TB_PIECE_ENTRY] = [];

	my $piece_chars = CP_PIECE_CHARS->[0];
	my $pchr = sub { ord $piece_chars->[CP_QUEEN - $_[0]] };

	my ($i, $j, $k, $l, $m);

	for ($i = 0; $i < 5; ++$i) {
		$self->__initTB(sprintf('K%cvK', $pchr->($i)));
	}

	for ($i = 0; $i < 5; ++$i) {
		for ($j = $i; $j < 5; ++$j) {
			$self->__initTB(sprintf('K%cvK%c', $pchr->($i), $pchr->($j)));
		}
	}

	for ($i = 0; $i < 5; ++$i) {
		for ($j = $i; $j < 5; ++$j) {
			$self->__initTB(sprintf('K%c%cvK', $pchr->($i), $pchr->($j)));
		}
	}

	for ($i = 0; $i < 5; ++$i) {
		for ($j = $i; $j < 5; ++$j) {
			for ($k = 0; $k < 5; ++$k) {
				$self->__initTB(sprintf('K%c%cvK%c',
						$pchr->($i), $pchr->($j), $pchr->($k)));
			}
		}
	}

	for ($i = 0; $i < 5; ++$i) {
		for ($j = $i; $j < 5; ++$j) {
			for ($k = $j; $k < 5; ++$k) {
				$self->__initTB(sprintf('K%c%c%cvK',
						$pchr->($i), $pchr->($j), $pchr->($k)));
			}
		}
	}

	for ($i = 0; $i < 5; ++$i) {
		for ($j = $i; $j < 5; ++$j) {
			for ($k = $i; $k < 5; ++$k) {
				for ($l = ($i == $k) ? $j : $k; $l < 5; ++$l) {
					$self->__initTB(sprintf('K%c%cvK%c%c',
							$pchr->($i), $pchr->($j),
							$pchr->($k), $pchr->($l)));
				}
			}
		}
	}

	for ($i = 0; $i < 5; ++$i) {
		for ($j = $i; $j < 5; ++$j) {
			for ($k = $j; $k < 5; ++$k) {
				for ($l = 0; $l < 5; ++$l) {
					$self->__initTB(sprintf('K%c%c%cvK%c',
						$pchr->($i), $pchr->($j), $pchr->($k), $pchr->($l)));
				}
			}
		}
	}

	for ($i = 0; $i < 5; ++$i) {
		for ($j = $i; $j < 5; ++$j) {
			for ($k = $j; $k < 5; ++$k) {
				for ($l = $k; $l < 5; ++$l) {
					$self->__initTB(sprintf('K%c%c%c%cvK',
							$pchr->($i), $pchr->($j), $pchr->($k), $pchr->($l)));
				}
			}
		}
	}

	for ($i = 0; $i < 5; ++$i) {
		for ($j = $i; $j < 5; ++$j) {
			for ($k = $j; $k < 5; ++$k) {
				for ($l = $k; $l < 5; ++$l) {
					for ($m = $l; $m < 5; ++$m) {
						$self->__initTB(sprintf('K%c%c%c%c%cvK',
								$pchr->($i), $pchr->($j), $pchr->($k),
								$pchr->($l), $pchr->($m)));
					}
				}
			}
		}
	}

	for ($i = 0; $i < 5; ++$i) {
		for ($j = $i; $j < 5; ++$j) {
			for ($k = $j; $k < 5; ++$k) {
				for ($l = $k; $l < 5; ++$l) {
					for ($m = 0; $m < 5; ++$m) {
						$self->__initTB(sprintf('K%c%c%c%cvK%c',
								$pchr->($i), $pchr->($j), $pchr->($k),
								$pchr->($l), $pchr->($m)));
					}
				}
			}
		}
	}

	for ($i = 0; $i < 5; ++$i) {
		for ($j = $i; $j < 5; ++$j) {
			for ($k = $j; $k < 5; ++$k) {
				for ($l = 0; $l < 5; ++$l) {
					for ($m = $l; $m < 5; ++$m) {
						$self->__initTB(sprintf('K%c%c%cvK%c%c',
								$pchr->($i), $pchr->($j), $pchr->($k),
								$pchr->($l), $pchr->($m)));
					}
				}
			}
		}
	}

	$self->[TB_LARGEST] = $self->[TB_MAX_CARDINALITY];
	if ($self->[TB_MAX_CARDINALITY_DTM] > $self->[TB_LARGEST]) {
		$self->[TB_LARGEST] = $self->[TB_MAX_CARDINALITY_DTM];
	}

	return $self;
}

sub __calcKeyFromPcs {
	my ($self, $pcs) = @_;

	return $pcs->[WHITE_QUEEN] * PRIME_WHITE_QUEEN
		+ $pcs->[WHITE_ROOK] * PRIME_WHITE_ROOK
		+ $pcs->[WHITE_BISHOP] * PRIME_WHITE_BISHOP
		+ $pcs->[WHITE_KNIGHT] * PRIME_WHITE_KNIGHT
		+ $pcs->[WHITE_PAWN] * PRIME_WHITE_PAWN
		+ $pcs->[BLACK_QUEEN] * PRIME_BLACK_QUEEN
		+ $pcs->[BLACK_ROOK] * PRIME_BLACK_ROOK
		+ $pcs->[BLACK_BISHOP] * PRIME_BLACK_BISHOP
		+ $pcs->[BLACK_KNIGHT] * PRIME_BLACK_KNIGHT
		+ $pcs->[BLACK_PAWN] * PRIME_BLACK_PAWN;
}

sub __calcKeyFromPcsMirrored {
	my ($self, $pcs) = @_;
	
	return $pcs->[WHITE_QUEEN ^ 8] * PRIME_WHITE_QUEEN
		+ $pcs->[WHITE_ROOK ^ 8] * PRIME_WHITE_ROOK
		+ $pcs->[WHITE_BISHOP ^ 8] * PRIME_WHITE_BISHOP
		+ $pcs->[WHITE_KNIGHT ^ 8] * PRIME_WHITE_KNIGHT
		+ $pcs->[WHITE_PAWN ^ 8] * PRIME_WHITE_PAWN
		+ $pcs->[BLACK_QUEEN ^ 8] * PRIME_BLACK_QUEEN
		+ $pcs->[BLACK_ROOK ^ 8] * PRIME_BLACK_ROOK
		+ $pcs->[BLACK_BISHOP ^ 8] * PRIME_BLACK_BISHOP
		+ $pcs->[BLACK_KNIGHT ^ 8] * PRIME_BLACK_KNIGHT
		+ $pcs->[BLACK_PAWN ^ 8] * PRIME_BLACK_PAWN;
}

sub __testTB {
	my ($self, $str, $suffix) = @_;

	my ($fh, $size) = $self->__openTB($str, $suffix) or return;
	$fh->close;
	if (($size & 63) != 16) {
		warn __x("Incomplete tablebase file {path}.\n",
		         path => "$str$suffix");
		return;
	}

	return $self;
}

sub __openTB {
	my ($self, $str, $suffix) = @_;

	my $relname = $str . $suffix;
	my $paths = $self->[TB_PATHS];
	foreach my $path (@$paths) {
		my $fullname = File::Spec->catfile($path, $relname);
		open my $fh, '<', $fullname or next;
		my $size = -s $fullname or next;
		return $fh, $size;
	}

	return;
}

sub __initTB {
	my ($self, $str) = @_;

	if (!$self->__testTB($str, TB_SUFFIX->[WDL])) {
		return;
	}

	my @pcs = (0) x 16;
	my $color = 0;
	foreach my $s (split //, $str) {
		if ('v' eq $s) {
			$color = 8;
		} else {
			my $piece = $char_to_piece_type[ord $s];
			if ($piece) {
				++$pcs[$piece | $color];
			}
		}
	}

	my $key = $self->__calcKeyFromPcs(\@pcs);
	my $key2 = $self->__calcKeyFromPcsMirrored(\@pcs);

	my $has_pawns = $pcs[TB_WPAWN] | $pcs[TB_BPAWN];

	my $be = {};
	if ($has_pawns) {
		push @{$self->[TB_PAWN_ENTRY]}, $be;
	} else {
		push @{$self->[TB_PIECE_ENTRY]}, $be;
	}

	$be->{has_pawns} = $has_pawns;
	$be->{key} = $key;
	$be->{symmetric} = $key == $key2;
	$be->{num} = 0;

	foreach my $pc (@pcs) {
		$be->{num} += $pc;
	}

	$be->{has_dtm} = $self->__testTB($str, TB_SUFFIX->[DTM]);
	$be->{has_dtz} = $self->__testTB($str, TB_SUFFIX->[DTZ]);

	if ($be->{num} > $self->[TB_MAX_CARDINALITY]) {
		$self->[TB_MAX_CARDINALITY] = $be->{num};
	}

	if ($be->{has_dtm}) {
		if ($be->{num} > $self->[TB_MAX_CARDINALITY]) {
			$self->[TB_MAX_CARDINALITY] = $be->{num};
		}
	}

	# These three values are initialized with atomic_init() in the original
	# code.
	$be->{ready} = [];

	# be.pawns resp. be.kk_enc is a union in C with a width of 8 bits.
	if ($has_pawns) {
		my $j = 0;
		foreach my $i (0 .. 15) {
			if ($pcs[$i] == 1) {
				++$j;
			}
			$be->{pawns} = $j == 2;
		}
	} else {
		my $pawns_0 = $pcs[TB_WPAWN];
		my $pawns_1 = $pcs[TB_BPAWN];
		if ($pawns_1 && (!$pawns_0 || $pawns_0 > $pawns_1)) {
			($pawns_0, $pawns_1) = ($pawns_1, $pawns_0);
		}
		$be->{pawns} = ($pawns_1 << 4) | $pawns_0;
	}

	$self->__addToHash($be, $key);
	if ($key != $key2) {
		$self->__addToHash($be, $key2);
	}
}

# FIXME! Maybe it is faster to just use a regular Perl hash for this.
sub __addToHash {
	my ($self, $ptr, $key) = @_;

	my $tb_hash = $self->[TB_HASH];
	my $idx = ($key >> (64 - TB_HASHBITS)) & TB_HASHMASK;
	while ($tb_hash->[$idx]->{ptr}) {
		$idx = ($idx + 1) & ((1 << (TB_HASHBITS)) - 1);
	}

	$tb_hash->[$idx]->{key} = $key;
	$tb_hash->[$idx]{ptr} = $ptr;
}

1;

=head1 NAME

Chess::Plisco::TableBase::Syzygy - Perl interface to Syzygy end-game table bases

=head1 SYNOPSIS

    $tb = Chess::Plisco::TableBase::Syzygy->new("./3-4-5");

=head1 DESCRIPTION

The module B<Chess::Plisco::TableBase::Syzygy> allows access to end-game
table bases in Syzygy format.

=head1 CONSTRUCTOR

=over 4

=item B<new PATH>

Initialize the database located at B<PATH>.

Throws an exception in case of an error.

B<PATH> can be a list of directories separated by a colon (':') resp. a
semi-colon ';' for MS-DOS/MS-Windows.

=back

=head1 METHODS

=over 4

=item B<largest>

Returns the maximum number of pieces for which the database can be probed.

A value of 0 means that no table files had been found at the path passsed as an
argument to the constructor.

=back

=head1 COPYRIGHT

Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>.

=head1 SEE ALSO

L<Chess::Plisco>(3pm), fathom(1), perl(1)
