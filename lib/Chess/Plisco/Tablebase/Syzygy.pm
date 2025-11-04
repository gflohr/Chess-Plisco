#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# This file is heavily inspired by python-chess.

package Chess::Plisco::Tablebase::Syzygy;

use strict;
use integer;

use Scalar::Util qw(reftype);
use Locale::TextDomain qw('Chess-Plisco');
use File::Spec;

use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

use constant UINT64_BE => 'Q>';
use constant UINT32 => 'L<';
use constant UINT32_BE => 'L>';
use constant UINT16 => 'S<';

use constant TBPIECES => 7;

use constant TRIANGLE => TRIANGLE = [
	6, 0, 1, 2, 2, 1, 0, 6,
	0, 7, 3, 4, 4, 3, 7, 0,
	1, 3, 8, 5, 5, 8, 3, 1,
	2, 4, 5, 9, 9, 5, 4, 2,
	2, 4, 5, 9, 9, 5, 4, 2,
	1, 3, 8, 5, 5, 8, 3, 1,
	0, 7, 3, 4, 4, 3, 7, 0,
	6, 0, 1, 2, 2, 1, 0, 6,
];

use constant INVTRIANGLE = [1, 2, 3, 10, 11, 19, 0, 9, 18, 27];

use constant TABLENAME_REGEX => qr/^[KQRBNP]+v[KQRBNP]+\Z/;
my $i = 0;
use constant PCHR => {map { $_ => $i++ } split '', 'KQRBNP'}; # FIXME! Needed?

# FIXME! These are candidates for macros!
my $offdiag = sub {
	my ($shift) = @_;

	my ($file, $rank) = cp_shift_to_coordinates $shift;

	return $rank - $file;
};

my $flipdiag = sub {
	my ($shift) = @_;

	return (($shift >> 3) | ($shift << 3)) & 63;
};

use constant LOWER => [
	28,  0,  1,  2,  3,  4,  5,  6,
	 0, 29,  7,  8,  9, 10, 11, 12,
	 1,  7, 30, 13, 14, 15, 16, 17,
	 2,  8, 13, 31, 18, 19, 20, 21,
	 3,  9, 14, 18, 32, 22, 23, 24,
	 4, 10, 15, 19, 22, 33, 25, 26,
	 5, 11, 16, 20, 23, 25, 34, 27,
	 6, 12, 17, 21, 24, 26, 27, 35,
];

use constant DIAG = [
	 0,  0,  0,  0,  0,  0,  0,  8,
	 0,  1,  0,  0,  0,  0,  9,  0,
	 0,  0,  2,  0,  0, 10,  0,  0,
	 0,  0,  0,  3, 11,  0,  0,  0,
	 0,  0,  0, 12,  4,  0,  0,  0,
	 0,  0, 13,  0,  0,  5,  0,  0,
	 0, 14,  0,  0,  0,  0,  6,  0,
	15,  0,  0,  0,  0,  0,  0,  7,
];

use constant FLAP => [
	0,  0,  0,  0,  0,  0,  0, 0,
	0,  6, 12, 18, 18, 12,  6, 0,
	1,  7, 13, 19, 19, 13,  7, 1,
	2,  8, 14, 20, 20, 14,  8, 2,
	3,  9, 15, 21, 21, 15,  9, 3,
	4, 10, 16, 22, 22, 16, 10, 4,
	5, 11, 17, 23, 23, 17, 11, 5,
	0,  0,  0,  0,  0,  0,  0, 0,
];

use constant PTWIST => [
	 0,  0,  0,  0,  0,  0,  0,  0,
	47, 35, 23, 11, 10, 22, 34, 46,
	45, 33, 21,  9,  8, 20, 32, 44,
	43, 31, 19,  7,  6, 18, 30, 42,
	41, 29, 17,  5,  4, 16, 28, 40,
	39, 27, 15,  3,  2, 14, 26, 38,
	37, 25, 13,  1,  0, 12, 24, 36,
	 0,  0,  0,  0,  0,  0,  0,  0,
];

use constant INVFLAP => [
	 8, 16, 24, 32, 40, 48,
	 9, 17, 25, 33, 41, 49,
	10, 18, 26, 34, 42, 50,
	11, 19, 27, 35, 43, 51,
];

use constant FILE_TO_FILE => [0, 1, 2, 3, 3, 2, 1, 0];

use constant KK_IDX => [[
	-1,  -1,  -1,   0,   1,   2,   3,   4,
	-1,  -1,  -1,   5,   6,   7,   8,   9,
	10,  11,  12,  13,  14,  15,  16,  17,
	18,  19,  20,  21,  22,  23,  24,  25,
	26,  27,  28,  29,  30,  31,  32,  33,
	34,  35,  36,  37,  38,  39,  40,  41,
	42,  43,  44,  45,  46,  47,  48,  49,
	50,  51,  52,  53,  54,  55,  56,  57,
], [
	 58,  -1,  -1,  -1,  59,  60,  61,  62,
	 63,  -1,  -1,  -1,  64,  65,  66,  67,
	 68,  69,  70,  71,  72,  73,  74,  75,
	 76,  77,  78,  79,  80,  81,  82,  83,
	 84,  85,  86,  87,  88,  89,  90,  91,
	 92,  93,  94,  95,  96,  97,  98,  99,
	100, 101, 102, 103, 104, 105, 106, 107,
	108, 109, 110, 111, 112, 113, 114, 115,
], [
	116, 117,  -1,  -1,  -1, 118, 119, 120,
	121, 122,  -1,  -1,  -1, 123, 124, 125,
	126, 127, 128, 129, 130, 131, 132, 133,
	134, 135, 136, 137, 138, 139, 140, 141,
	142, 143, 144, 145, 146, 147, 148, 149,
	150, 151, 152, 153, 154, 155, 156, 157,
	158, 159, 160, 161, 162, 163, 164, 165,
	166, 167, 168, 169, 170, 171, 172, 173,
], [
	174,  -1,  -1,  -1, 175, 176, 177, 178,
	179,  -1,  -1,  -1, 180, 181, 182, 183,
	184,  -1,  -1,  -1, 185, 186, 187, 188,
	189, 190, 191, 192, 193, 194, 195, 196,
	197, 198, 199, 200, 201, 202, 203, 204,
	205, 206, 207, 208, 209, 210, 211, 212,
	213, 214, 215, 216, 217, 218, 219, 220,
	221, 222, 223, 224, 225, 226, 227, 228,
], [
	229, 230,  -1,  -1,  -1, 231, 232, 233,
	234, 235,  -1,  -1,  -1, 236, 237, 238,
	239, 240,  -1,  -1,  -1, 241, 242, 243,
	244, 245, 246, 247, 248, 249, 250, 251,
	252, 253, 254, 255, 256, 257, 258, 259,
	260, 261, 262, 263, 264, 265, 266, 267,
	268, 269, 270, 271, 272, 273, 274, 275,
	276, 277, 278, 279, 280, 281, 282, 283,
], [
	284, 285, 286, 287, 288, 289, 290, 291,
	292, 293,  -1,  -1,  -1, 294, 295, 296,
	297, 298,  -1,  -1,  -1, 299, 300, 301,
	302, 303,  -1,  -1,  -1, 304, 305, 306,
	307, 308, 309, 310, 311, 312, 313, 314,
	315, 316, 317, 318, 319, 320, 321, 322,
	323, 324, 325, 326, 327, 328, 329, 330,
	331, 332, 333, 334, 335, 336, 337, 338,
], [
	-1,  -1, 339, 340, 341, 342, 343, 344,
	-1,  -1, 345, 346, 347, 348, 349, 350,
	-1,  -1, 441, 351, 352, 353, 354, 355,
	-1,  -1,  -1, 442, 356, 357, 358, 359,
	-1,  -1,  -1,  -1, 443, 360, 361, 362,
	-1,  -1,  -1,  -1,  -1, 444, 363, 364,
	-1,  -1,  -1,  -1,  -1,  -1, 445, 365,
	-1,  -1,  -1,  -1,  -1,  -1,  -1, 446,
], [
	-1,  -1,  -1, 366, 367, 368, 369, 370,
	-1,  -1,  -1, 371, 372, 373, 374, 375,
	-1,  -1,  -1, 376, 377, 378, 379, 380,
	-1,  -1,  -1, 447, 381, 382, 383, 384,
	-1,  -1,  -1,  -1, 448, 385, 386, 387,
	-1,  -1,  -1,  -1,  -1, 449, 388, 389,
	-1,  -1,  -1,  -1,  -1,  -1, 450, 390,
	-1,  -1,  -1,  -1,  -1,  -1,  -1, 451,
], [
	452, 391, 392, 393, 394, 395, 396, 397,
	 -1,  -1,  -1,  -1, 398, 399, 400, 401,
	 -1,  -1,  -1,  -1, 402, 403, 404, 405,
	 -1,  -1,  -1,  -1, 406, 407, 408, 409,
	 -1,  -1,  -1,  -1, 453, 410, 411, 412,
	 -1,  -1,  -1,  -1,  -1, 454, 413, 414,
	 -1,  -1,  -1,  -1,  -1,  -1, 455, 415,
	 -1,  -1,  -1,  -1,  -1,  -1,  -1, 456,
], [
	457, 416, 417, 418, 419, 420, 421, 422,
	 -1, 458, 423, 424, 425, 426, 427, 428,
	 -1,  -1,  -1,  -1,  -1, 429, 430, 431,
	 -1,  -1,  -1,  -1,  -1, 432, 433, 434,
	 -1,  -1,  -1,  -1,  -1, 435, 436, 437,
	 -1,  -1,  -1,  -1,  -1, 459, 438, 439,
	 -1,  -1,  -1,  -1,  -1,  -1, 460, 440,
	 -1,  -1,  -1,  -1,  -1,  -1,  -1, 461,
]];

use constant PP_IDX => [[
	 0,  -1,   1,   2,   3,   4,   5,   6,
	 7,   8,   9,  10,  11,  12,  13,  14,
	15,  16,  17,  18,  19,  20,  21,  22,
	23,  24,  25,  26,  27,  28,  29,  30,
	31,  32,  33,  34,  35,  36,  37,  38,
	39,  40,  41,  42,  43,  44,  45,  46,
	-1,  47,  48,  49,  50,  51,  52,  53,
	54,  55,  56,  57,  58,  59,  60,  61,
], [
	 62,  -1,  -1,  63,  64,  65,  -1,  66,
	 -1,  67,  68,  69,  70,  71,  72,  -1,
	 73,  74,  75,  76,  77,  78,  79,  80,
	 81,  82,  83,  84,  85,  86,  87,  88,
	 89,  90,  91,  92,  93,  94,  95,  96,
	 -1,  97,  98,  99, 100, 101, 102, 103,
	 -1, 104, 105, 106, 107, 108, 109,  -1,
	110,  -1, 111, 112, 113, 114,  -1, 115,
], [
	116,  -1,  -1,  -1, 117,  -1,  -1, 118,
	 -1, 119, 120, 121, 122, 123, 124,  -1,
	 -1, 125, 126, 127, 128, 129, 130,  -1,
	131, 132, 133, 134, 135, 136, 137, 138,
	 -1, 139, 140, 141, 142, 143, 144, 145,
	 -1, 146, 147, 148, 149, 150, 151,  -1,
	 -1, 152, 153, 154, 155, 156, 157,  -1,
	158,  -1,  -1, 159, 160,  -1,  -1, 161,
], [
	162,  -1,  -1,  -1,  -1,  -1,  -1, 163,
	 -1, 164,  -1, 165, 166, 167, 168,  -1,
	 -1, 169, 170, 171, 172, 173, 174,  -1,
	 -1, 175, 176, 177, 178, 179, 180,  -1,
	 -1, 181, 182, 183, 184, 185, 186,  -1,
	 -1,  -1, 187, 188, 189, 190, 191,  -1,
	 -1, 192, 193, 194, 195, 196, 197,  -1,
	198,  -1,  -1,  -1,  -1,  -1,  -1, 199,
], [
	200,  -1,  -1,  -1,  -1,  -1,  -1, 201,
	 -1, 202,  -1,  -1, 203,  -1, 204,  -1,
	 -1,  -1, 205, 206, 207, 208,  -1,  -1,
	 -1, 209, 210, 211, 212, 213, 214,  -1,
	 -1,  -1, 215, 216, 217, 218, 219,  -1,
	 -1,  -1, 220, 221, 222, 223,  -1,  -1,
	 -1, 224,  -1, 225, 226,  -1, 227,  -1,
	228,  -1,  -1,  -1,  -1,  -1,  -1, 229,
], [
	230,  -1,  -1,  -1,  -1,  -1,  -1, 231,
	 -1, 232,  -1,  -1,  -1,  -1, 233,  -1,
	 -1,  -1, 234,  -1, 235, 236,  -1,  -1,
	 -1,  -1, 237, 238, 239, 240,  -1,  -1,
	 -1,  -1,  -1, 241, 242, 243,  -1,  -1,
	 -1,  -1, 244, 245, 246, 247,  -1,  -1,
	 -1, 248,  -1,  -1,  -1,  -1, 249,  -1,
	250,  -1,  -1,  -1,  -1,  -1,  -1, 251,
], [
	-1,  -1,  -1,  -1,  -1,  -1,  -1, 259,
	-1, 252,  -1,  -1,  -1,  -1, 260,  -1,
	-1,  -1, 253,  -1,  -1, 261,  -1,  -1,
	-1,  -1,  -1, 254, 262,  -1,  -1,  -1,
	-1,  -1,  -1,  -1, 255,  -1,  -1,  -1,
	-1,  -1,  -1,  -1,  -1, 256,  -1,  -1,
	-1,  -1,  -1,  -1,  -1,  -1, 257,  -1,
	-1,  -1,  -1,  -1,  -1,  -1,  -1, 258,
], [
	-1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
	-1,  -1,  -1,  -1,  -1,  -1, 268,  -1,
	-1,  -1, 263,  -1,  -1, 269,  -1,  -1,
	-1,  -1,  -1, 264, 270,  -1,  -1,  -1,
	-1,  -1,  -1,  -1, 265,  -1,  -1,  -1,
	-1,  -1,  -1,  -1,  -1, 266,  -1,  -1,
	-1,  -1,  -1,  -1,  -1,  -1, 267,  -1,
	-1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
], [
	-1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
	-1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
	-1,  -1,  -1,  -1,  -1, 274,  -1,  -1,
	-1,  -1,  -1, 271, 275,  -1,  -1,  -1,
	-1,  -1,  -1,  -1, 272,  -1,  -1,  -1,
	-1,  -1,  -1,  -1,  -1, 273,  -1,  -1,
	-1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
	-1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
], [
	-1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
	-1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
	-1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
	-1,  -1,  -1,  -1, 277,  -1,  -1,  -1,
	-1,  -1,  -1,  -1, 276,  -1,  -1,  -1,
	-1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
	-1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
	-1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
]];

use constant TEST45_MASK => (1 << (CP_A5)) | (1 << (CP_A6)) | (1 << (CP_A7)) | (1 << (CP_B5)) | (1 << (CP_B6)) | (1 << (CP_C5));

my $test45 = sub {
	my ($shift) = @_;

	return !!((1 << $shift) & TEST45_MASK);
};

sub new {
	my ($class, $directory, %__options) = @_;

	my %options = (
		loadWdl => 1,
		loadDtz => 1,
		maxFds => 128,
		%__options
	);

	my $self = bless {
		__wdl => {},
		__dtz => {},
	}, $class;

	$self->addDirectory($directory, %options) if defined $directory;

	return $self;
}

sub addDirectory {
	my ($self, $directory, %__options) = @_;

	my %options = (
		loadWdl => 1,
		loadDtz => 1,
		%__options
	);

	$directory = File::Spec->rel2abs($directory);

	opendir my $dh, $directory or return 0;
	my @files = readdir $dh;

	my $num_files = 0;
	my $largest = 0;
	my $smallest = 0;
	foreach my $filename (@files) {
		my $path = File::Spec->catfile($directory, $filename);

		next if $filename !~ /(.*)\.([^.]+)$/;
		my ($tablename, $ext) = ($1, $2);

		if ($self->__isTablename($tablename) && -f $path) {
			if ($options{loadWdl} && 'rtbw' eq $ext) {
				$num_files += $self->__openTable($self->{__wdl}, 'WDL', $path);
			}
			if ($options{loadDtz} && 'rtbz' eq $ext) {
				$num_files += $self->__openTable($self->{__dtz}, 'DTZ', $path);
			}
		}
	}

	# FIXME! Describe better what has been found.
	return $num_files;
}

sub __openTable {
	my ($self, $hashtable, $class, $path) = @_;

	my $name = $path;
	$name =~ s/\.[^.]+$//;
	$name =~ s{.*[/\\]}{};

	my $table = 
	$hashtable->{$name} = {};

	return $self;
}

sub __isTablename {
	my ($self, $name, %options) = @_;

	%options = (
		normalized => 1,
		%options,
	);

	return (
		$name =~ TABLENAME_REGEX
		&& (!$options{normalized} || $self->normalizeTablename($name) eq $name)
		&& $name ne 'KvK' && 'K' eq substr $name, 0, 1 && $name =~ /vK/
	);
}

sub largestWdl {
	my ($self) = @_;

	my $max = 0;
	foreach my $table (keys %{$self->{__wdl}}) {
		my $num_pieces = (length $table) - 1;
		$max = $num_pieces if $num_pieces > $max;
	}

	return $max;
}

sub largestDtz {
	my ($self) = @_;

	my $max = 0;
	foreach my $table (keys %{$self->{__dtz}}) {
		my $num_pieces = (length $table) - 1;
		$max = $num_pieces if $num_pieces > $max;
	}

	return $max;
}

sub largest {
	my ($self) = @_;

	my $largestWdl = $self->largestWdl;
	my $largestDtz = $self->largestDtz;

	return $largestWdl < $largestDtz ? $largestWdl : $largestDtz;
}

sub normalizeTablename {
	my ($self, $name, $mirror) = @_;

	my ($white, $black) = split 'v', $name;

	$white = join '', sort { PCHR->{$a} <=> PCHR->{$b} } split //, $white;
	$black = join '', sort { PCHR->{$a} <=> PCHR->{$b} } split '', $black;

	if ($mirror
	    ^ ((length($white) < length($black))
	       && ((join '', map { PCHR->{$_} } split '', $black)
		       lt (join '', map { PCHR->{$_} } split '', $white)))) {
		return join 'v', $black, $white;
	} else {
		return join 'v', $white, $black;
	}
}

sub probeWdl {
	my ($self, $pos) = @_;

	my ($value) = $self->__probeAb($pos, -2, 2);

	# FIXME! Check en-passant!

	return $value;
}

sub getWdl {
	my ($self, $pos) = @_;

	my $result;
	eval {
		$result = $self->probeWdl($pos);
	};
	if ($@ && $@ ne __("Missing table!\n")) {
		die $@;
	}

	return $result;
}

sub __probeAb {
	my ($self, $pos, $alpha, $beta) = @_;

	if ($pos->castlingRights) {
		die __x("Syzygy tables do not contain positions with castling rights: {fen}",
			fen => $pos->toFEN);
	}

	my $piece_count;
	cp_bitboard_popcount $pos->occupied, $piece_count;

	if ($piece_count > TBPIECES + 1) {
		die __x("syzygy tables support up to {TBPIECES} pieces, not {piece_count}: {fen}",
			TBPIECES => TBPIECES,
			piece_count => $piece_count,
			fen => $pos->toFEN);
	}

	# Iterate over all non-ep captures.
	my $en_passant_shift = cp_pos_en_passant_shift $pos;
	my $v;
	foreach my $move ($pos->legalMoves) {
		my $captured;
		cp_move_captured $move, $captured;

		if (!$captured) {
			next;
		}

		if ($en_passant_shift) {
			my $to = cp_move_to $move;
			if ($en_passant_shift == $to) {
				next;
			}
		}

		$pos->doMove($move);
		my $v_plus = $self->__probeAb($pos, -$beta, -$alpha);
		$v = -$v_plus;
		$pos->undoMove($move);

		if ($v > $alpha) {
			if ($v >= $beta) {
				return $v, 2;
			}

			$alpha = $v;
		}

	}

	TODO: $v = $self->__probeWdlTable($pos);

	if ($alpha >= $v) {
		return $alpha, 1 + $alpha > 0;
	}

	return $v, 1
}

sub __probeWdlTable {
	my ($self, $pos) = @_;

	return 42;
}

sub __initTableWdl {

}

1;

=head1 NAME

Chess::Plisco::Tablebase::Syzygy - Perl interface to Syzygy end-game table bases

=head1 SYNOPSIS

    $tb = Chess::Plisco::Tablebase::Syzygy->new("./3-4-5");

=head1 DESCRIPTION

Warning! This is work in progress and not ready!

The module B<Chess::Plisco::Tablebase::Syzygy> allows access to end-game
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

Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>.

=head1 SEE ALSO

L<Chess::Plisco>(3pm), fathom(1), perl(1)
