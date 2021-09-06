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
use Chess::Position qw(:all);
use Chess::Position::Macro;

my @tests = (
	{
		name => 'start position',
		fen => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
		material => 0,
	},
	{
		name => 'lisco vs. PANTELIS39 after 34. Kd3',
		fen => '4r3/pp5p/2p1Nkpn/8/2B5/3K4/PP6/8 b - - 7 34',
		material => CP_BISHOP_VALUE - 3 * CP_PAWN_VALUE - CP_ROOK_VALUE,
	},
	{
		name => 'lisco vs. PANTELIS39 34. Rxe6',
		fen => '4r3/pp5p/2p1Nkpn/8/2B5/3K4/PP6/8 b - - 7 34',
		move => 'Rxe6',
		material => CP_BISHOP_VALUE - CP_KNIGHT_VALUE - 3 * CP_PAWN_VALUE - CP_ROOK_VALUE,
	},
	{
		name => 'lisco vs. PANTELIS39 34. ...Bxe6',
		fen => '8/pp5p/2p1rkpn/8/2B5/3K4/PP6/8 w - - 0 35',
		move => 'Bxe6',
		material => CP_BISHOP_VALUE - CP_KNIGHT_VALUE - 3 * CP_PAWN_VALUE,
	},
	{
		name => 'lisco vs. PANTELIS39 35. Kxe6',
		fen => '8/pp5p/2p1Bkpn/8/8/3K4/PP6/8 b - - 0 35',
		move => 'Kxe6',
		material => -CP_KNIGHT_VALUE - 3 * CP_PAWN_VALUE,
	},
);

plan tests => scalar @tests;

foreach my $test (@tests) {
	my $pos = Chess::Position->new($test->{fen});
	if ($test->{move}) {
		my $move = $pos->parseMove($test->{move})
			or die "$test->{name}: invalid move $test->{move}";
		$pos->doMove($test->{move})
			or die "$test->{name}: illegal move $test->{move}";
	}
	is(cp_pos_material($pos), $test->{material}, "$test->{name}");
}
