#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.


package Chess::Position::Move;

use strict;
use integer;

use Locale::TextDomain qw('Chess-Position');
use Chess::Position qw(:all);
use Chess::Position::Macro;

sub new {
	my ($class, $notation, $position) = @_;

	if ($notation =~ /^([a-h][1-8])([a-h][1-8])([qrbn])?$/i) {
		return Chess::Position::Move->__newFromCoordinates(map { lc $_ } ($1, $2, $3))
	}

	require Carp;
	Carp::croak("SAN parser not yet implemented.\n");
}

sub __newFromCoordinates {
	my ($class, $from_square, $to_square, $promote) = @_;

	my $self = 0;
	my $from = cp_square_to_shift $from_square;
	my $to = cp_square_to_shift $to_square;

	cp_move_set_from($self, $from);
	cp_move_set_to($self, $to);

	if ($promote) {
		my %pieces = (
			q => CP_QUEEN,
			r => CP_ROOK,
			b => CP_BISHOP,
			n => CP_KNIGHT,
		);

		cp_move_set_promote($self, $pieces{$promote});
	}

	bless \$self, $class;
}

sub from {
	my ($self) = @_;

	return cp_move_from $$self;
}

sub to {
	my ($self) = @_;

	return cp_move_to $$self;
}

sub promote {
	my ($self) = @_;

	return cp_move_promote $$self;
}

sub toInteger {
	my ($self) = @_;

	return $$self;
}

sub toString {
	my ($self) = @_;

	return cp_move_coordinate_notation $$self;
}

1;
