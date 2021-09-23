#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine::TranspositionTable;

use strict;
use integer;

use constant ENTRY_SIZE => 16;

sub new {
	my ($class, $size) = @_;

	my $self = [];
	bless $self, $class;

	return $self->resize($size);
}

sub clear {
	my ($self) = @_;

	my $size = @$self;

	$#$self = 0;
	$#$self = $size;

	return $self;
}

sub resize {
	my ($self, $size) = @_;

	$self->clear;
	$#$self = (1024 * 1024 / ENTRY_SIZE) - 1;

	return $self;
}

sub probe {
	my ($self, $lookup_key) = @_;

	my $entry = $self->[$lookup_key % scalar @$self] or return;

	my ($stored_key, $payload) = @$entry;
	return if $stored_key != $lookup_key;

	return [unpack 'S4', $payload];
}

sub store {
	my ($self, $key, $depth, $flags, $value, $move) = @_;

	# Replacement scheme is currently replace-always.
	my $payload = pack 'S4', $depth, $flags, $value, $move;

	$self->[$key % scalar @$self] = [$key, $payload];
}

1;
