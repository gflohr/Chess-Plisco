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
use Time::HiRes qw(gettimeofday);

sub make_move;

my ($pos, @moves, @expect);

my @tests = (
	{
		name => 'white pawn gives check',
		before => '8/8/4k3/2n5/3Pp3/5N2/5K2/8 w - - 0 1',
		move => 'd5+',
		check => 1,
	},
	{
		name => 'white pawn does not give check',
		before => '8/8/4k3/2n5/3Pp3/5N2/5K2/8 w - - 0 1',
		move => 'dxc5',
		check => 0,
	},
	{
		name => 'black pawn gives check',
		before => '8/8/4k3/2n5/3Pp3/5N2/5K2/8 b - - 0 1',
		move => 'e3+',
		check => 1,
	},
	{
		name => 'black pawn does not give check',
		before => '8/8/4k3/2n5/3Pp3/5N2/5K2/8 b - - 0 1',
		move => 'exf3',
		check => 0,
	},
	{
		name => 'white knight gives check',
		before => '8/8/4k2n/8/8/1N6/5K2/8 w - - 0 1',
		move => 'Nd4+',
		check => 1,
	},
	{
		name => 'white knight does not give check',
		before => '8/8/4k2n/8/8/1N6/5K2/8 w - - 0 1',
		move => 'Na5',
		check => 0,
	},
	{
		name => 'black knight gives check',
		before => '8/8/4k2n/8/8/1N6/5K2/8 b - - 0 1',
		move => 'Ng4+',
		check => 1,
	},
	{
		name => 'black knight does not give check',
		before => '8/8/4k2n/8/8/1N6/5K2/8 b - - 0 1',
		move => 'Ng8',
		check => 0,
	},
	{
		name => 'white bishop gives check',
		before => '7b/8/4k3/8/8/8/5K2/3B4 w - - 0 1',
		move => 'Bb3+',
		check => 1,
	},
	{
		name => 'white bishop does not give check',
		before => '7b/8/4k3/8/8/8/5K2/3B4 w - - 0 1',
		move => 'Bc2',
		check => 0,
	},
	{
		name => 'black bishop gives check',
		before => '7b/8/4k3/8/8/8/5K2/3B4 b - - 0 1',
		move => 'Bd4+',
		check => 1,
	},
	{
		name => 'black bishop does not give check',
		before => '7b/8/4k3/8/8/8/5K2/3B4 b - - 0 1',
		move => 'Be5',
		check => 0,
	},
	{
		name => 'white rook gives check',
		before => '8/8/4k3/1r6/8/8/2R2K2/8 w - - 0 1',
		move => 'Rc6+',
		check => 1,
	},
	{
		name => 'white rook does not give check',
		before => '8/8/4k3/1r6/8/8/2R2K2/8 w - - 0 1',
		move => 'Rc3',
		check => 0,
	},
	{
		name => 'black rook gives check',
		before => '8/8/4k3/1r6/8/8/2R2K2/8 b - - 0 1',
		move => 'Rf5+',
		check => 1,
	},
	{
		name => 'black rook does not give check',
		before => '8/8/4k3/1r6/8/8/2R2K2/8 b - - 0 1',
		move => 'Re5',
		check => 0,
	},
	{
		name => 'white gives check by king-side castling',
		before => '5k2/8/8/8/8/8/8/R3K2R w KQ - 0 1',
		move => 'O-O',
		check => 1,
	},
	{
		name => 'white gives check by queen-side castling',
		before => '3k4/8/8/8/8/8/8/R3K2R w KQ - 0 1',
		move => 'O-O-O',
		check => 1,
	},
	{
		name => 'black gives check by king-side castling',
		before => 'r3k2r/8/8/8/8/8/8/5K2 b kq - 0 1',
		move => 'O-O',
		check => 1,
	},
	{
		name => 'black gives check by queen-side castling',
		before => 'r3k2r/8/8/8/8/8/8/3K4 b kq - 0 1',
		move => 'O-O-O',
		check => 1,
	},
);

plan tests => @tests << 1;

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{before});
	my $move = $pos->parseMove($test->{move});
	ok $move, "$test->{name}: parse $test->{move}";

	if ($test->{check}) {
		ok $pos->moveGivesCheck($move),
			"$test->{name}: $test->{move} gives check";
	} else {
		ok !$pos->moveGivesCheck($move),
			"$test->{name}: $test->{move} does not give check";
	}
}
