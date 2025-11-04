#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# This file is heavily inspired by python-chess.

use strict;
use integer;

use File::Spec;
use List::Util qw(reduce);
use Locale::TextDomain qw('Chess-Plisco');
use Scalar::Util qw(reftype);

use constant UINT64_BE => 'Q>';
use constant UINT32 => 'L<';
use constant UINT32_BE => 'L>';
use constant UINT16 => 'S<';

use constant TRIANGLE => [
	6, 0, 1, 2, 2, 1, 0, 6,
	0, 7, 3, 4, 4, 3, 7, 0,
	1, 3, 8, 5, 5, 8, 3, 1,
	2, 4, 5, 9, 9, 5, 4, 2,
	2, 4, 5, 9, 9, 5, 4, 2,
	1, 3, 8, 5, 5, 8, 3, 1,
	0, 7, 3, 4, 4, 3, 7, 0,
	6, 0, 1, 2, 2, 1, 0, 6,
];

use constant INVTRIANGLE => [1, 2, 3, 10, 11, 19, 0, 9, 18, 27];

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

use constant DIAG => [
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

use constant MTWIST => [
	15, 63, 55, 47, 40, 48, 56, 12,
	62, 11, 39, 31, 24, 32,  8, 57,
	54, 38,  7, 23, 16,  4, 33, 49,
	46, 30, 22,  3,  0, 17, 25, 41,
	45, 29, 21,  2,  1, 18, 26, 42,
	53, 37,  6, 20, 19,  5, 34, 50,
	61, 10, 36, 28, 27, 35,  9, 58,
	14, 60, 52, 44, 43, 51, 59, 13,
];

my @PAWNIDX = ([], [], [], [], []);
my @PFACTOR = ([], [], [], [], []);

my $binom = sub {
	my ($x, $y) = @_;

	use integer;

	my $numerator = reduce { $a * $b } $x - $y + 1 .. $x;
	my $denominator = reduce { $a * $b } 1 .. $y;

	return $numerator / $denominator;
};

for my $i (0 .. 4) {
	my $j = 0;

	my $s = 0;
	while ($j < 6) {
		$PAWNIDX[$i]->[$j] = $s;
		$s += $i == 0 ? 1 : $binom->(PTWIST->[INVFLAP->[$j]], $i);
		++$j;
	}
	$PFACTOR[$i]->[0] = $s;

	$s = 0;
	while ($j < 12) {
		$PAWNIDX[$i]->[$j] = $s;
		$s += $i == 0 ? 1 : $binom->(PTWIST->[INVFLAP->[$j]], $i);
		++$j;
	}
	$PFACTOR[$i]->[1] = $s;

	$s = 0;
	while ($j < 18) {
		$PAWNIDX[$i]->[$j] = $s;
		$s += $i == 0 ? 1 : $binom->(PTWIST->[INVFLAP->[$j]], $i);
		++$j;
	}
	$PFACTOR[$i]->[2] = $s;

	$s = 0;
	while ($j < 24) {
		$PAWNIDX[$i]->[$j] = $s;
		$s += $i == 0 ? 1 : $binom->(PTWIST->[INVFLAP->[$j]], $i);
		++$j;
	}
	$PFACTOR[$i][3] = $s;
}

my @MULTIDX = ([], [], [], [], []);
my @MFACTOR;

for my $i (0 .. 4) {
	my $s = 0;
	for my $j (0 .. 9) {
		$MULTIDX[$i]->[$j] = $s;
		$s += $i == 0 ? 1 : $binom->(MTWIST->[INVTRIANGLE->[$j]], $i);
		++$j;
	}
	$MFACTOR[$i] = $s;
}

use constant WDL_TO_MAP => [1, 3, 0, 2, 0];

use constant PA_FLAGS => [8, 0, 0, 0, 4];

use constant WDL_TO_DTZ => [-1, -101, 0, 101, 1];

use constant PCHR => ['K', 'Q', 'R', 'B', 'N', 'P'];
my %PCHR_IDX = map { PCHR->[$_] => $_ } 0 .. $#{ PCHR() };

use constant TABLENAME_REGEX => qr/^[KQRBNP]+v[KQRBNP]+\Z/;

my $normalize_tablename = sub {
	my ($name, $mirror) = @_;

	my ($w, $b) = split /v/, $name, 2;

	# Sort pieces according to PCHR order.
	$w = join '', sort { $PCHR_IDX{$a} <=> $PCHR_IDX{$b} } split //, $w;
	$b = join '', sort { $PCHR_IDX{$a} <=> $PCHR_IDX{$b} } split //, $b;

	# Build the comparison arrays.
	my @b_indices = map { $PCHR_IDX{$_} } split //, $b;
	my @w_indices = map { $PCHR_IDX{$_} } split //, $w;

	# Compare tuples: (length, array).
	my $swap = 0;
	for my $i (0 .. @w_indices) {
		my $w_val = $i == 0 ? length($w) : $w_indices[$i-1];
		my $b_val = $i == 0 ? length($b) : $b_indices[$i-1];
		if ($w_val != $b_val) {
			$swap = 1 if $mirror ^ ($b_val < $w_val);
			last;
		}
	}

	return $swap ? $b . "v" . $w : $w . "v" . $b;
};

my $is_tablename = sub {
	my ($name, %options) = @_;

	%options = (
		normalized => 1,
		%options,
	);

	return (
		$name =~ TABLENAME_REGEX
		&& (!$options{normalized} || $normalize_tablename->($name) eq $name)
		&& $name ne 'KvK' && 'K' eq substr $name, 0, 1 && $name =~ /vK/
	);
};

my $_dependencies = sub {
	my ($target, $one_king) = @_;

	$one_king //= 1;

	my ($w, $b) = split /v/, $target, 2;

	my @result;

	for my $p (@{PCHR()}) {
		next if $p eq 'K' && $one_king;

		# Promotions
		if ($p ne 'P' && $w =~ /P/) {
			my $new_name = $w;
			$new_name =~ s/P/$p/;
			push @result, $normalize_tablename->($new_name . 'v' . $b);
		}
		if ($p ne 'P' && $b =~ /P/) {
			my $new_name = $b;
			$new_name =~ s/P/$p/;
			push @result, $normalize_tablename->($w . 'v' . $new_name);
		}

		# Captures
		if ($w =~ /\Q$p\E/ && length($w) > 1) {
			my $new_name = $w;
			$new_name =~ s/\Q$p\E//;
			push @result, $normalize_tablename->($new_name . 'v' . $b);
		}
		if ($b =~ /\Q$p\E/ && length($b) > 1) {
			my $new_name = $b;
			$new_name =~ s/\Q$p\E//;
			push @result, $normalize_tablename->($w . 'v' . $new_name);
		}
	}

	return @result;
};

my $all_dependencies = sub {
	my ($targets, $one_king) = @_;

	$one_king //= 1;

	my %closed;
	$closed{"KvK"} = 1 if $one_king;

	my @open_list = map { $normalize_tablename->($_) } @$targets;

	my @result;

	while (@open_list) {
		my $name = pop @open_list;
		next if $closed{$name};

		push @result, $name;
		$closed{$name} = 1;

		push @open_list, _dependencies($name, one_king => $one_king);
	}

	return \@result;
};

my $tablenames = sub {
	my ($one_king, $piece_count) = @_;

	$one_king //= 1;
	$piece_count //= 6;

	my $first = $one_king ? 'K' : 'P';

	my @targets;

	my $white_pieces = $piece_count - 2;
	my $black_pieces = 0;

	while ($white_pieces >= $black_pieces) {
		push @targets, $first . ('P' x $white_pieces) . 'v' . $first . ('P' x $black_pieces);
		$white_pieces--;
		$black_pieces++;
	}

	return $all_dependencies->(\@targets, $one_king);
};

my $calc_key = sub {
	my ($pos, $mirror) = @_;

	$mirror //= 0;

	my ($wh, $bl) = ($pos->[CP_POS_WHITE_PIECES], $pos->[CP_POS_BLACK_PIECES]);

	my @pieces = qw(P N B R Q);

	my ($wkey, $bkey) = ('K', 'K');
	foreach my $i (reverse CP_POS_PAWNS .. CP_POS_QUEENS) {
		my $popcount;

		cp_bitboard_popcount $pos->[$i] & $wh, $popcount;
		$wkey .= $pieces[$i - CP_POS_PAWNS] x $popcount;

		cp_bitboard_popcount $pos->[$i] & $bl, $popcount;
		$bkey .= $pieces[$i - CP_POS_PAWNS] x $popcount;
	}

	return $mirror ? (join 'v', $wkey, $bkey) : (join 'v', $bkey, $wkey);
};

# Some endgames are stored with a different key than their filename
# indicates: http://talkchess.com/forum/viewtopic.php?p=695509#695509
my $recalc_key = sub {
	my ($pieces, $mirror) = @_;

	$mirror //= 0;

	my ($w, $b) = $mirror ? (8, 0) : (0, 8);
	my @order  = (6, 5, 4, 3, 2, 1);
	my @letters = qw(K Q R B N P);

	my $key = join(
		'',
		# white side
		map { my $n = grep { $_ == ($_ ^ $w) } @$pieces; $letters[$_] x $n } 0 .. $#order,
		'v',
		# black side
		map { my $n = grep { $_ == ($_ ^ $b) } @$pieces; $letters[$_] x $n } 0 .. $#order
	);

	return $key;
};

my $subfactor = sub {
	my ($k, $n) = @_;

	my $f = $n;
	my $l = 1;

	for my $i (1 .. $k - 1) {
		$f *= $n - $i;
		$l *= $i + 1;
	}

	return int($f / $l);
};

my $dtz_before_zeroing = sub {
	my ($wdl) = @_;

	my $sign = ($wdl > 0 ? 1 : 0) - ($wdl < 0 ? 1 : 0);
	my $factor = (abs($wdl) == 2 ? 1 : 101);

	return $sign * $factor;
};

package PairsData;

sub new {
	my ($class, %args) = @_;

	bless {
		indextable => $args{indextable} // 0,
		sizetable => $args{sizetable} // 0,
		data => $args{data} // 0,
		offset => $args{offset} // 0,
		symlen => $args{symlen} // [],
		sympat => $args{sympat} // 0,
		blocksize => $args{blocksize} // 0,
		idxbits => $args{idxbits} // 0,
		min_len => $args{min_len} // 0,
		base => $args{base} // [],
	}, $class;
}

package PawnFileData;

sub new {
	my ($class) = @_;
	bless {
		precomp => {},
		factor  => {},
		pieces  => {},
		norm    => {},
	}, $class;
}

package PawnFileDataDtz;
sub new {
	my ($class, %args) = @_;

	bless {
		precomp => $args{precomp} // PairsData->new(),
		factor  => $args{factor}  // [],
		pieces  => $args{pieces}  // [],
		norm    => $args{norm}    // [],
	}, $class;
}

package Table;

use Fcntl qw(O_RDONLY O_BINARY);
use Sys::Mmap qw(mmap PROT_READ MAP_SHARED);

sub new {
	my ($class, $path) = @_;

	my $self = {};

	$self->{path} = $path;

	# Normalize tablename
	my ($basename) = $path =~ m{([^/]+)$};
	$basename =~ s/\.[^.]+$//;
	$self->{key} = $normalize_tablename->($basename);
	$self->{mirrored_key} = $normalize_tablename->($basename, 1);
	$self->{symmetric} = $self->{key} eq $self->{mirrored_key};

	$self->{num} = length($basename) - 1;

	$self->{has_pawns} = ($basename =~ /P/);

	my ($black_part, $white_part) = split /v/, $basename;

	if ($self->{has_pawns}) {
		$self->{pawns} = [
			() = $white_part =~ /P/g,
			() = $black_part =~ /P/g,
		];

		if ($self->{pawns}->[1] > 0
			&& ($self->{pawns}->[0] == 0 || $self->{pawns}->[1] < $self->{pawns}->[0]))
		{
			($self->{pawns}->[0], $self->{pawns}->[1]) =
				($self->{pawns}->[1], $self->{pawns}->[0]);
		}
	} else {
		my $j = 0;
		foreach my $piece_type (@{PCHR()}) {
			$j++ if ($black_part =~ /$piece_type/ && ($black_part =~ tr/$piece_type/$piece_type/) == 1);
			$j++ if ($white_part =~ /$piece_type/ && ($white_part =~ tr/$piece_type/$piece_type/) == 1);
		}

		if ($j >= 3) {
			$self->{enc_type} = 0;
		} else {
			$self->{enc_type} = 2;
		}
	}

	bless $self, $class;
}

sub _initMmap {
	my ($self) = @_;

	return if defined $self->{data};

	# Open the file.
	sysopen(my $fh, $self->{path}, O_RDONLY | ($^O eq 'MSWin32' ? O_BINARY : 0))
		or die __x("Cannot open '{path}': {error}\n",
			path => $self->{path}, error => $@);

	# Get the file size.
	my $size = -s $fh;

	# Memory-map the file.
	my $data;
	mmap($data, $size, PROT_READ, MAP_SHARED, $fh)
		or die __x("Cannot mmap '{path}': {error}\n",
			path => $self->{path}, error => $@);

	close($fh);

	# Validate the file size.
	die __x("Invalid file size: Ensure '{path}' is a valid syzygy tablebase.\n",
			path => $self->{path})
		if $size % 64 != 16;

	# Store the memory-mapped string in the object.
	$self->{data} = \$data;
}

sub __checkMagic {
	my ($self, $magic, $pawnless_magic) = @_;

	if (!$self->{data}) {
		die __x("Cannot check magic in '{path}' without data.\n",
			path => $self->{path})
	}

	my @valid_magics = ($magic);

	push @valid_magics, $pawnless_magic if $self->{has_pawns};

	my $header = substr(${$self->{data}}, 0, 4);

	my $ok = 0;
	for my $m (@valid_magics) {
		next unless defined $m;
		if ($header eq $m) {
			$ok = 1;
			last;
		}
	}

	if (!$ok) {
		die __x("Invalid magic header! Ensure that '{path}' is a valid syzygy tablebase file.\n",
			path => $self->{path});
	}
}

sub __setupPairs {
	my ($self, $data_ptr, $tb_size, $size_idx, $wdl) = @_;

	if (!$self->{data}) {
		die __x("Cannot setup pairs for '{path}' without data.\n",
			path => $self->{path})
	}

	my $d = new PairsData;

	$self->{_flags} = $self->{data}[$data_ptr];

	if ($self->{data}->[$data_ptr] & 0x80) {
		$d->{idxbits} = 0;

		if ($wdl) {
			$d->{min_len} = $self->{data}->[$data_ptr + 1];
		} else {
			# http://www.talkchess.com/forum/viewtopic.php?p=698093#698093
			$d->{min_len} = 0;
		}

		$self->{_next} = $data_ptr + 2;
		$self->{size}->[$size_idx + 0] = 0;
		$self->{size}->[$size_idx + 1] = 0;
		$self->{size}->[$size_idx + 2] = 0;

		return $d;
	}

	$d->{blocksize} = $self->{data}->[$data_ptr + 1];
	$d->{idxbits} = $self->{data}->[$data_ptr + 2];

	my $real_num_blocks = $self->__readUint32($data_ptr + 4);
	my $num_blocks = $real_num_blocks + $self->{data}->[$data_ptr + 3];
	my $max_len = $self->{data}->[$data_ptr + 8];
	my $min_len = $self->{data}->[$data_ptr + 9];
	my $h = $max_len - $min_len + 1;
	my $num_syms = $self->__readUint16($data_ptr + 10 + 2 * $h);

	${d}->{offset} = $data_ptr + 10;
	${d}->{symlen} = [0 .. $h * 8 + $num_syms - 1];
	${d}->{sympat} = $data_ptr + 12 + 2 * $h;
	${d}->{min_len} = $min_len;

	$self->{_next} = $data_ptr + 12 + 2 * $h + 3 * $num_syms + ($num_syms & 1);

	my $num_indices = ($tb_size + (1 << $d->{idxbits}) - 1) >> $d->{idxbits};
	$self->{size}->[$size_idx + 0] = 6 * $num_indices;
	$self->{size}->[$size_idx + 1] = 2 * $num_blocks;
	$self->{size}->[$size_idx + 2] = (1 << $d->{blocksize}) * $real_num_blocks;

	my @tmp = (0 .. $num_syms - 1);
	for my $i (0 .. $num_syms - 1) {
		if (!$tmp[$i]) {
			$self->_calcSymlen($d, $i, \@tmp)
		}
	}

	$d->{base} = [0 .. $h - 1];
	$d->{base}->[$h - 1] = 0;

	for my $i (reverse 0 .. $h - 2) {
		$d->{base}->[$i] = ($d->{base}->[$i + 1]
			+ $self.__readUint16($d->{offset} + $i * 2)
			- $self->__readUint16($d->{offset} + $i * 2 + 2)) // 2;
	}

	for my $i (0 .. $h) {
		$d->{base}->[$i] <<= 64 - ($min_len + $i);
	}

	$d->{offset} -= 2 * $d->{min_len};

	return $d;
}

package Chess::Plisco::Tablebase::Syzygy;

use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

use constant TBPIECES => 7;

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

		if ($is_tablename->($tablename) && -f $path) {
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
