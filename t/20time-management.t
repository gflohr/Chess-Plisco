#! /usr/bin/env perl

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More;
use Chess::Plisco::Engine::TimeControl;

my $EVALUATION = 5;
my $MOVES_TO_GO = Chess::Plisco::Engine::TimeControl::MovesToGo::MOVES_TO_GO->[$EVALUATION];

my @tests = (
	{
		name => 'line ' . __LINE__,
		wtime => 60000,
		btime => 60000,
		movestogo => 40,
		allocated => 1500,
	},
	{
		name => 'line ' . __LINE__,
		wtime => 60000,
		btime => 60000,
		allocated => int(0.5 + 60000 / $MOVES_TO_GO),
	},
	{
		name => 'line ' . __LINE__,
		wtime => 60000,
		btime => 20000,
		movestogo => 40,
		allocated => 1500 + int(3 * (40000 - 1500) / 4),
	}
);

plan tests => scalar @tests;

foreach my $test (@tests) {
	use integer; # So does the search tree.

	my %tree = (
		position => TestPosition->new,
	);
	my $tm = Chess::Plisco::Engine::TimeControl->new(\%tree, %$test);
	is $tree{allocated_time}, $test->{allocated}, $test->{name};
}

package TestPosition;

sub new {
	bless {}, shift;
}

sub toMove {
	return 0;
}

sub evaluate {
	return $EVALUATION;
}