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

	my $move;
	if ($notation =~ /^([a-h][1-8])([a-h][1-8])([qrbn])?$/i) {
		$move = Chess::Position::Move->__parseCoordinates(map { lc $_ } ($1, $2, $3))
	} else {
		require Carp;
		Carp::croak("SAN parser not yet implemented.\n");
	}

	my $attacker;
	my $from_mask = 1 << (cp_move_from $move);

	if ($from_mask & cp_pos_pawns($position)) {
		$attacker = CP_PAWN;
	} elsif ($from_mask & cp_pos_knights($position)) {
		$attacker = CP_KNIGHT;
	} elsif ($from_mask & cp_pos_bishops($position)) {
		if ($from_mask & cp_pos_rooks($position)) {
			$attacker = CP_QUEEN;
		} else {
			$attacker = CP_BISHOP;
		}
	} elsif ($from_mask & cp_pos_rooks($position)) {
		$attacker = CP_ROOK;
	} elsif ($from_mask & cp_pos_kings($position)) {
		$attacker = CP_KING;
	} else {
		require Carp;
		Carp::croak(__"Illegal move: start square is empty.\n");
	}

	cp_move_set_attacker($move, $attacker);

	bless {
		__move => $move,
		__position => $position,
	}, $class;
}

sub __parseCoordinates {
	my ($class, $from_square, $to_square, $promote) = @_;

	my $move = 0;
	my $from = cp_square_to_shift $from_square;
	my $to = cp_square_to_shift $to_square;

	cp_move_set_from($move, $from);
	cp_move_set_to($move, $to);

	if ($promote) {
		my %pieces = (
			q => CP_QUEEN,
			r => CP_ROOK,
			b => CP_BISHOP,
			n => CP_KNIGHT,
		);

		cp_move_set_promote($move, $pieces{$promote});
	}

	return $move;
}

sub from {
	my ($self) = @_;

	return cp_move_from $self->{__move};
}

sub to {
	my ($self) = @_;

	return cp_move_to $self->{__move};
}

sub promote {
	my ($self) = @_;

	return cp_move_promote $self->{__move};
}

sub toInteger {
	my ($self) = @_;

	return $self->{__move};
}

sub toString {
	my ($self) = @_;

	return cp_move_coordinate_notation $self->{__move};
}

1;
