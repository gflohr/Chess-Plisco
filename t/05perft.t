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

my @tests = (
	{
		name => "Start position",
		perft => [20, 400, 8902, 197281],
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Position->new($test->{fen});
	my @perfts = @{$test->{perft}};

	for (my $depth = 1; $depth <= @perfts; ++$depth) {
		my $expect = $perfts[$depth - 1];
		my $got = $pos->perft($depth);
		is $got, $expect, "perft depth $depth ($test->{name})";
	}
}

done_testing;
