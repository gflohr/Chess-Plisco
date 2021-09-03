#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More;
use File::Basename qw(dirname);
use File::Spec;

use Chess::Position qw(:all);

sub report_failure;

eval { require Chess::PGN::Parse };
if ($@) {
	plan skip_all => 'You have to install PGN::Parse to run these tests.';
	exit 0;
}

my $dir = dirname __FILE__;
my $pgn_file = File::Spec->catfile($dir, 'Flohr.pgn');

ok -e $pgn_file, 'Flohr.pgn exists';

ok open my $fh, '<', $pgn_file;

my $num_tests = 0;
foreach my $line (<$fh>) {
	++$num_tests if $line =~ /^\[^Event/;
}

my $pgn = Chess::PGN::Parse->new($pgn_file);
ok $pgn, 'Flohr.pgn loaded';

my $seconds_per_test = $ENV{CP_SECONDS_PER_TEST} || 10;

my $started = time;
my $done_tests = 0;
GAME: while ($pgn->read_game) {
	my $pos = Chess::Position->new;

	$pgn->parse_game;

	my @moves;
	my @undoInfos;
	my @fen = ($pos->toFEN);
	my @positions = ($pos->copy);

	my $sans = $pgn->moves;

	foreach my $san (@$sans) {
		my $halfmove = 1 + @moves;
		my $move = $pos->parseMove($san);
		if (!$move) {
			report_failure $pgn, $pos,
				"\ncannot parse move '$san'\n", $halfmove;
			last;
		}

		my $undoInfo = $pos->doMove($move);
		if (!$undoInfo) {
			report_failure $pgn, $pos,
				"\ncannot apply move '$san'\n", $halfmove;
			last;
		} else {
			ok $undoInfo, "do move $san for position $pos";
		}
		push @moves, $move;
		push @undoInfos, $undoInfo;
		push @fen, $pos->toFEN;
		push @positions, $pos->copy;
	}

	pop @fen;
	pop @positions;

	while (@moves) {
		my $move = pop @moves;
		my $undoInfo = pop @undoInfos;
		$pos->undoMove($move, $undoInfo);
		my $wanted_fen = pop @fen;
		my $got_fen = $pos->toFEN;
		my $halfmove = 1 + @moves;
		if ($wanted_fen ne $got_fen) {
			report_failure $pgn, $pos,
				"\nwanted FEN: '$wanted_fen'\n   got FEN: '$got_fen'\n", $halfmove;
		} else {
			ok 1;
		}
		my $wanted_position = pop @positions;
		if (!$pos->equals($wanted_position)) {
			report_failure $pgn, $pos,
				"\nwanted position: '$wanted_position'\n   got position: '$pos'\n", $halfmove;
		} else {
			ok 1;
		}
		--$halfmove;
	}

	if (time - $started > $seconds_per_test) {
		last;
	}
}

done_testing;

sub report_failure {
	my ($pgn, $pos, $reason, $halfmove) = @_;

	my $tags = $pgn->tags;

	my $location = '';
	if (defined $halfmove) {
		my $moves = $pgn->moves;
		my $move = $moves->[$halfmove - 1];
		my $moveno = 1 + $halfmove >> 1;
		my $fill = $halfmove & 1 ? '' : '...';
		$location = "\n$moveno. $fill$move"
	}
	chomp $reason;

	my $fen = $pos->toFEN;

	diag <<EOF;
Test failed at '$pgn_file':
	[White "$tags->{White}"]
	[Black "$tags->{Black}"]
	[Event "$tags->{Event}"]
	[Date "$tags->{Date}"]$location
FEN: $fen
Reason: $reason
EOF

	diag $pos->dumpInfo;
	diag $pos->dumpAll;

	ok 0, 'see above';
	ok $pos->consistent;

	exit 1;
}