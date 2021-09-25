#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package EPDSolver;

use strict;

use Test::More;

use Chess::Plisco::EPD;
use Chess::Plisco::Engine::Tree;
use Chess::Plisco::Engine::Position;
use Chess::Plisco::Engine::TranspositionTable;
use Chess::Plisco::Engine::TimeControl;

sub new {
	my ($class, $epdfile, %params) = @_;

	%params = (depth => 3) unless %params;

	my $epd = Chess::Plisco::EPD->new($epdfile);
	plan tests => scalar $epd->records;

	my $self = bless {
		__epd => $epd,
		__filename => $epdfile,
		__watcher => DummyWatcher->new,
		__params => \%params,
	}, $class;
}

sub epd {
	shift->{__epd};
}

sub __solve {
	my ($self, $record, $lineno) = @_;

	my $bm = $record->operation('bm');
	my $am = $record->operation('am');
	my $id = $record->operation('id');
	my $location = "$self->{__filename}:$lineno ($id)";

	if (!($bm || $am)) {
		die "$location: neither bm no am found";
	}

	my $position = $record->position;
	bless $position, 'Chess::Plisco::Engine::Position';

	if ($bm) {
		my $move = $position->parseMove($bm)
			or die "$location: illegal or invalid bm '$bm'.";
		$bm = $position->moveCoordinateNotation($move);
	}
	if ($am) {
		my $move = $position->parseMove($am)
			or die "$location: illegal or invalid bm '$am'.";
		$am = $position->moveCoordinateNotation($move);
	}

	my $dm = $record->operation('dm');
	my %params = %{$self->{__params}};
	if ($dm) {
		$params{mate} = $dm;
	}

	my $tree = Chess::Plisco::Engine::Tree->new(
		$position,
		Chess::Plisco::Engine::TranspositionTable->new(16),
		$self->{__watcher},
		sub {},
		[$position->signature],
	);
	my $tc = Chess::Plisco::Engine::TimeControl->new($tree, %params);
$DB::single = 1;
	my $move = $position->moveCoordinateNotation($tree->think);
	if ($bm) {
		is $move, $bm, "$location: best move";
	} elsif ($am) {
		isnt $move, $am, "$location: avoid move";
	}
}

sub solve {
	my ($self) = @_;

	my @records = $self->{__epd}->records;

	my $lineno = 0;
	foreach my $record (@records) {
		$self->__solve($record, ++$lineno);
	}
}

package DummyWatcher;

use strict;

sub new {
	my ($class) = @_;

	my $self = '';

	bless \$self, $class;
}

sub check {}

1;
