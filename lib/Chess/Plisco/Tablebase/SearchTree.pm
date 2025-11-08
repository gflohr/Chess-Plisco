#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Tablebase::SearchTree;

use strict;
use integer;

use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

use constant INF => 32767;

sub new {
	my ($class, $tb, %options) = @_;

	bless {
		__tb => $tb,
		__game_over => 0,
		__pv => [[]],
		__max_depth => 0,
		__nodes => 0,
	}, $class;
}

sub search {
	my ($self, $pos, $wdl) = @_;

	$self->{__game_over} = 0;
	$self->{__max_depth} = 0;
	$self->{__nodes} = 0;
	$self->{__wdl} = 0;

	while (1) {
		my @line;
		my $score = $self->negamax(1, $pos, $self->{__max_depth}, $wdl - 1, $wdl + 1, \@line);
		warn "Nodes searched at depth $self->{__max_depth}: $self->{__nodes}\n";
		if ($self->{__game_over}) {
			return @line;
		}
		++$self->{__max_depth};
	}
}

sub negamax {
	my ($self, $ply, $pos, $depth, $alpha, $beta, $pline) = @_;

	++$self->{__nodes};

	my @line;

	if ($depth <= 0) {
		my $probe_value = $self->{__tb}->probeWdl($pos);
		$self->{__game_over} = $self->{__tb}->gameOver;

		return $probe_value;
	}

	my @legal = $pos->legalMoves;

	my ($min_value, $max_value);

	foreach my $move ($pos->legalMoves) {
		my $san = $pos->SAN($move);
		my $to_move = $pos->toMove;
		my $undo = $pos->doMove($move);
		my $value = -$self->negamax($ply + 1, $pos, $depth - 1, -$beta, -$alpha, \@line);
		warn "To move: $to_move, $value <=> $self->{__wdl}\n";
		$pos->undoMove($undo);

		if ($value > $alpha || ($self->{__game_over} && $value >= $alpha)) {
			$alpha = $value;
			@$pline = ($san, @line);

			return $alpha if $self->{__game_over};
		}

		# This must come after changing the principal variation because the
		# optimal move will also cause a beta-cutoff if another move with the
		# same outcome has already been checked.
		if ($value >= $beta) {
			return $beta;
		}
	}

	return $alpha;
}

1;
