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
use Chess::Position::Move;

my ($pos, @moves, @expect);

my @tests = (
	{
		name => 'white knight pinned by rook',
		move => 'e4g5',
		fen => '8/4r2k/8/8/4N3/8/4K3/8 w - - 0 1',
		pinned => 1,
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Position->new($test->{fen});
	my $name = $test->{name} . " on $test->{square}";
	my $move = Chess::Position::Move->new($test->{move}, $pos)->toInteger;

	if ($test->{pinned}) {
		ok $pos->pinned($move), $name;
	} else {
		not_ok $pos->pinned($move), $name;
	}
}

done_testing;
