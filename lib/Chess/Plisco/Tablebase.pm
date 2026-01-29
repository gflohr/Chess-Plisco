#! /bin/false

# Copyright (C) 2021-2026 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Tablebase;

use strict;
use integer;

use Chess::Plisco::Engine::Position;

sub getPV {
	my ($self, $_pos) = @_;

	# Upgrade the position and make a copy of it.
	my $pos = Chess::Plisco::Engine::Position->newFromFEN($_pos->toFEN);

	my $wdl = $self->probeWdl($pos);
	my $minimise_dtz;
	if ($wdl > 0) {
		$minimise_dtz = 1;
	} elsif ($wdl < 0) {
		$minimise_dtz = 0;
	}

	my @pv;
	MOVE: while (!$pos->gameOver) {
		$wdl = -$wdl;
		my ($best_dtz, $best_move);
		my @moves = $pos->legalMoves;
		my @backup = @$pos;
		foreach my $move (@moves) {
			$pos->move($move);
			my $next_wdl = $self->safeProbeWdl($pos);
			last MOVE if !defined $next_wdl;
			if ($next_wdl != $wdl) {
				@$pos = @backup;
				next;
			}

			my $next_dtz = abs $self->safeProbeDtz($pos);
			@$pos = @backup;
			next if !defined $next_dtz;

			if (!defined $best_dtz || ($minimise_dtz != ($next_dtz > $best_dtz))) {
				$best_dtz = $next_dtz;
				$best_move = $move;
			}
		}

		push @pv, $best_move;

		# If the game is a draw, we decide from move to move what seems to be
		# the better strategy, otherwise, the perspective changes with every
		# move.
		if ($wdl == 0) {
			$minimise_dtz = $self->__getMinimiseDtz($pos);
		} else {
			$minimise_dtz = !$minimise_dtz;
		}

		die "should not happen" if !$best_move;
		$pos->move($best_move);
	}

	return @pv;
}

sub __getMinimiseDtz {
	my ($self, $pos) = @_;

	# This assumes that the position is a draw. The side that seems to be
	# ahead will try to minimise the DTZ.
	my $score = $pos->evaluate;

	return $score < 0;
}

1;
