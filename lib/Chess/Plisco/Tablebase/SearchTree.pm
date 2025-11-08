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
	my ($self, $pos) = @_;

	$self->{__game_over} = 0;
	$self->{__max_depth} = 0;
	$self->{__nodes} = 0;
	$self->{__line} = [];
	while (1) {
		my @line;
		my $score = -$self->negamax(1, $pos, $self->{__max_depth}, -INF, INF, \@line);
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

	# FIXME! Only probe at leaves!
	my $probe_value = $self->{__tb}->probeWdl($pos);
	my $game_over = $self->{__game_over} = $self->{__tb}->gameOver;
	if ($depth <= 0) {
		print join ' ', @{$self->{__line}}, "$probe_value\n";
		return cp_pos_to_move($pos) ? $probe_value : $probe_value;
	}
	
	if ($game_over) {
		if ($game_over & CP_GAME_WHITE_WINS) {
			return 2;
		} elsif ($game_over & CP_GAME_BLACK_WINS) {
			return -2;
		} else {
			return 0;
		}
	}

	my @legal = $pos->legalMoves;

	foreach my $move ($pos->legalMoves) {
		my $san = $pos->SAN($move);
		push @{$self->{__line}}, $san;
		my $undo = $pos->doMove($move);
		my $value = -$self->negamax($ply + 1, $pos, $depth - 1, -$beta, -$alpha, \@line);
		pop @{$self->{__line}};
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
