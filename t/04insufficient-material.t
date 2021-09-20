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
use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

my @tests = (
	{
		name => 'nothing',
		fen => 'k7/8/8/8/8/8/8/7K w - - 10 20',
		draw => 1,
	},
	{
		name => 'white bishop',
		fen => 'k7/8/8/7B/8/8/8/7K w - - 10 20',
		draw => 1,
	},
	{
		name => 'black bishop',
		fen => 'k7/8/8/7b/8/8/8/7K w - - 10 20',
		draw => 1,
	},
	{
		name => 'white knight',
		fen => 'k7/8/8/7N/8/8/8/7K w - - 10 20',
		draw => 1,
	},
	{
		name => 'black knight',
		fen => 'k7/8/8/7n/8/8/8/7K w - - 10 20',
		draw => 1,
	},
	{
		name => 'bishop vs. bishop on same color',
		fen => 'k7/8/8/5B1b/8/8/8/7K w - - 10 20',
		draw => 1,
	},
	{
		name => 'bishop vs. bishop on different color',
		fen => 'k7/8/8/6Bb/8/8/8/7K w - - 10 20',
		draw => 0,
	},
	{
		name => 'two black knights',
		fen => 'k7/8/8/6nn/8/8/8/7K w - - 10 20',
		draw => 1,
	},
	{
		name => 'three black knights',
		fen => 'k7/8/8/5nnn/8/8/8/7K w - - 10 20',
		draw => 0,
	},
);

plan tests => scalar @tests;

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	if ($test->{draw}) {
		ok $pos->insufficientMaterial, "$test->{name} should be draw";
	} else {
		ok !$pos->insufficientMaterial, "$test->{name} should not be draw";
	}
}
