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
use Chess::Position qw(:all);
use Chess::Position::Macro;

my ($pos, @moves, @expect);

my @tests = (
	# Castlings.
	{
		name => 'white pawn checks on f5',
		fen => '8/8/4k3/5P2/8/8/8/4K3 b - - 0 1',
		checkers => [(1 << (CP_F_MASK & CP_5_MASK))],
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Position->new($test->{fen});
	ok cp_pos_in_check($pos), "$test->{name} but opponent is not in check";
	ok cp_pos_checkers($pos), "$test->{name} but wrong checkers mask"
}

done_testing;
