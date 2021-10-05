#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine::Tree;

use strict;
use integer;

use Locale::TextDomain qw('Chess-Plisco');

use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;
use Chess::Plisco::Engine::TranspositionTable;

use Time::HiRes qw(tv_interval);

use constant DEBUG => 0;

use constant MATE => -15000;
use constant INF => 16383;
use constant MAX_PLY => 512;
use constant DRAW => 0;

# These values get stored in the upper 32 bits of a moves so that they are
# searched first.
use constant MOVE_ORDERING_PV => 1 << 62;
use constant MOVE_ORDERING_TT => 1 << 61;

# For all combinations of promotion piece and captured piece, calculate a
# value suitable for sorting.  We choose the raw material balance minus the
# piece that moves.  That way, captures that the queen makes are less
# "attractive" than captures that the rook makes.
my @move_values = (0) x 369;

sub new {
	my ($class, $position, $tt, $watcher, $info, $signatures) = @_;

	# Make sure that the reversible clock does not look beyond the know
	# positions.  This will simplify the detection of a draw by repetition.
	if ($position->[CP_POS_REVERSIBLE_CLOCK] >= @$signatures) {
		$position->[CP_POS_REVERSIBLE_CLOCK] = @$signatures - 1;
	}

	my $self = {
		position => $position,
		signatures => $signatures,
		history_length => -1 + scalar @$signatures,
		tt => $tt,
		watcher => $watcher,
		info => $info || sub {},
	};

	bless $self, $class;
}

sub checkTime {
	my ($self) = @_;

	$self->{watcher}->check;

	no integer;

	my $elapsed = 1000 * tv_interval($self->{start_time});

	# Taken from Stockfish: Start printing the current move after 0.5 s.
	# Otherwise the output is getting messy in the beginning.  Stockfish is
	# using 3 s but we are slower.
	if ($elapsed > 500) {
		$self->{print_current_move} = 1;
	}
	my $allocated = $self->{allocated_time};
	my $eta = $allocated - $elapsed;
	if ($eta < 4 && !$self->{max_depth} && !$self->{max_nodes}) {
		die "PLISCO_ABORTED\n";
	}

	my $nodes = $self->{nodes};
	my $nps = $elapsed ? (1000 * $nodes / $elapsed) : 10000;
	my $max_nodes_to_tc = $nps >> 3;

	if ($self->{max_depth}) {
		$self->{nodes_to_tc} = $nodes + $max_nodes_to_tc;
	} elsif ($self->{max_nodes}) {
		$self->{nodes_to_tc} =
			cp_min($nodes + $max_nodes_to_tc, $self->{max_nodes});
	} else {
		my $nodes_to_tc = int(($eta * $nps) / 2000);

		$self->{nodes_to_tc} = $nodes + 
			(($nodes_to_tc < $max_nodes_to_tc) ? $nodes_to_tc : $max_nodes_to_tc);
	}
}

sub debug {
	my ($self, $msg) = @_;

	chomp $msg;
	print "DEBUG $msg\n";

	return 1;
}

sub indent {
	my ($self, $ply, $msg) = @_;

	chomp $msg;
	my $indent = '..' x ($ply - 1);
	$self->debug("[$ply] $indent$msg");
}

# __BEGIN_MACROS__
sub printPV {
	my ($self, $pline) = @_;

	no integer;
	my $position = $self->{position};
	my $score = $self->{score};
	my $mate_in;
	if ($score >= -(MATE + MAX_PLY)) {
		$mate_in = (1 - (MATE + $score)) >> 1;
	} elsif ($score <= (MATE + MAX_PLY)) {
		use integer;
		$mate_in = (MATE - $score) >> 1;
	}

	my $nodes = $self->{nodes};
	my $elapsed = tv_interval($self->{start_time});
	my $nps = $elapsed ? (int(0.5 + $nodes / $elapsed)) : 0;
	my $scorestr = $mate_in ? "mate $mate_in" : "cp $score";
	my $pv = join ' ', $position->movesCoordinateNotation(@$pline);
	my $time = int(0.5 + (1000 * $elapsed));
	my $seldepth = @$pline;
	$self->{info}->("depth $self->{depth} seldepth $self->{seldepth}"
			. " score $scorestr nodes $nodes nps $nps time $time pv $pv");
	if ($self->{__debug}) {
		$self->{info}->("tt_hits $self->{tt_hits}") if $self->{__debug};
	}
}

sub alphabeta {
	my ($self, $ply, $depth, $alpha, $beta, $pline, $is_pv) = @_;

	my @line;

	if ($self->{nodes} >= $self->{nodes_to_tc}) {
		$self->checkTime;
	}

	my $position = $self->{position};

	if (DEBUG) {
		my $hex_signature = sprintf '%016x', $position->signature;
		$self->indent($ply, "alphabeta: alpha = $alpha, beta = $beta,"
			. " sig: $hex_signature $position");
		if ($is_pv) {
			$self->indent($ply, "in PV");
		}
	}

	if (cp_pos_half_move_clock($position) >= 100
		|| $position->insufficientMaterial) {
		if (DEBUG) {
			$self->indent($ply, "draw detected");
		}
		return DRAW;
	}

	# Check draw by repetition.  FIXME! Try to find near repetitions with
	# cuckoo tables.
	#
	# We know that the reversible clock is never pointing beyond the known
	# positions/signatures because that gets adjusted in the constructor.
	my $signatures = $self->{signatures};
	my $signature = $position->[CP_POS_SIGNATURE];
	if ($ply > 1) {
		my $rc = $position->reversibleClock; # FIXME! Use this!!!
		my $history_length = $self->{history_length};
		my $signature_slot = $history_length + $ply;
		my $max_back = $signature_slot - $rc - 1;
		my $repetitions = 0;
		for (my $n = $signature_slot - 5; $n >= $max_back; $n -= 2) {
			if ($signatures->[$n] == $signature) {
				++$repetitions;
				if ($repetitions >= 2 || $n >= $history_length) {
					if (DEBUG) {
						$self->indent($ply, "3-fold repetition");
					}
					return DRAW;
				}
			}
		}
	}

	my $tt = $self->{tt};
	my $tt_move;
	if (DEBUG) {
		my $hex_sig = sprintf '%016x', $signature;
		$self->indent($ply, "TT probe $hex_sig \@depth $depth, alpha = $alpha, beta = $beta");
	}
	my $tt_value = $tt->probe($signature, $depth, $alpha, $beta, \$tt_move);

	if (DEBUG) {
		if ($tt_move) {
			my $cn = $position->moveCoordinateNotation($tt_move);
			$self->indent($ply, "best move: $cn");
		}
	}
	if (defined $tt_value) {
		++$self->{tt_hits};
		if ($tt_move && $ply == 1) {
			@$pline = ($tt_move);
			$self->{score} = $tt_value;
		}

		if (DEBUG) {
			my $hex_sig = sprintf '%016x', $signature;
			my $cn = $position->moveCoordinateNotation($tt_move);
			$self->indent($ply, "TT hit for $hex_sig, value $tt_value, best move $cn");
		}
		return $tt_value;
	}

	if ($depth <= 0) {
		return $self->quiesce($ply, $alpha, $beta, $pline, $is_pv);
	}

	my @moves = $position->pseudoLegalMoves;

	# Expand the moves with a score so that they can be sorted.
	my ($pawns, $knights, $bishops, $rooks, $queens) = 
		@$position[CP_POS_PAWNS .. CP_POS_QUEENS];
	my $pos_info = cp_pos_info $position;
	my $her_pieces = $position->[CP_POS_WHITE_PIECES + cp_pos_info_to_move $pos_info];
	my $ep_shift = cp_pos_info_en_passant_shift $pos_info;
	my $pv_move;
	$pv_move = $pline->[$ply - 1] if @$pline >= $ply;
	my $found = 0;
	foreach my $move (@moves) {
		if (cp_move_equivalent $move, $pv_move) {
			$move |= MOVE_ORDERING_PV;
			++$found;
		} elsif (cp_move_equivalent $move, $tt_move) {
			$move |= MOVE_ORDERING_TT;
			++$found;
		} elsif ($depth > 1) {
			$move |= $position->SEE($move) << 32;
		} else {
			last if $found >= 2;
		}
	}

	# Now sort the moves according to the material gain.
	@moves = sort { $b <=> $a } @moves;

	my $legal = 0;
	my $pv_found;
	my $tt_type = Chess::Plisco::Engine::TranspositionTable::TT_SCORE_ALPHA();
	my $best_move = 0;
	my $print_current_move = $ply == 1 && $self->{print_current_move};
	my $signature_slot = $self->{history_length} + $ply;
	foreach my $move (@moves) {
		my $state = $position->doMove($move) or next;
		$signatures->[$signature_slot] = $position->[CP_POS_SIGNATURE];
		++$legal;
		++$self->{nodes};
		$self->printCurrentMove($depth, $move, $legal) if $print_current_move;
		my $val;
		if (DEBUG) {
			my $cn = $position->moveCoordinateNotation($move);
			$self->indent($ply, "move $cn: start search");
		}
		if ($pv_found) {
			if (DEBUG) {
				$self->indent($ply, "null window search");
			}
			$val = -$self->alphabeta($ply + 1, $depth - 1,
					-$alpha - 1, -$alpha, \@line, $is_pv && !$legal);
			if (($val > $alpha) && ($val < $beta)) {
				if (DEBUG) {
					$self->indent($ply, "value $val outside null window, re-search");
				}
				$val = -$self->alphabeta($ply + 1, $depth - 1,
						-$beta, -$alpha, \@line, $is_pv && !$legal);
			}
		} else {
			if (DEBUG) {
				$self->indent($ply, "recurse normal search");
			}
			$val = -$self->alphabeta($ply + 1, $depth - 1,
					-$beta, -$alpha, \@line, $is_pv && !$legal);
		}
		if (DEBUG) {
			$self->indent($ply, "value: $val");
		}
		$position->undoMove($state);
		if ($val >= $beta) {
			if (DEBUG) {
				my $hex_sig = sprintf '%016x', $signature;
				my $cn = $position->moveCoordinateNotation($move);
				$self->indent($ply, "$cn fail high ($val >= $beta), store $val(BETA) \@depth $depth for $hex_sig");
			}
			$tt->store($signature, $depth,
				Chess::Plisco::Engine::TranspositionTable::TT_SCORE_BETA(),
				$val, $move);
			return $beta;
		}
		if ($val > $alpha) {
			$alpha = $val;
			$pv_found = 1;
			@$pline = ($move, @line);
			$tt_type = Chess::Plisco::Engine::TranspositionTable::TT_SCORE_EXACT();
			$best_move = $move;
	
			if (DEBUG) {
				$self->indent($ply, "raise alpha to $alpha");
			}
			if ($is_pv) {
				$self->{score} = $val;
				$self->printPV($pline);
			}
		}
	}

	if (!$legal) {
		# Mate or stalemate.
		if (!$position->inCheck) {
			$alpha = DRAW;
		} else {
			$alpha = MATE + $self->{depth} - $depth + 1;
		}
		if (DEBUG) {
			$self->indent($ply, "mate/stalemate, score: $alpha");
		}
	}

	if (DEBUG) {
		my $hex_sig = sprintf '%016x', $signature;
		my $type;
		if ($tt_type == TT_SCORE_ALPHA) {
			$type = 'ALPHA';
		} else {
			$type = 'EXACT';
		}
		$self->indent($ply, "returning alpha $alpha, store ($type) \@depth $depth for $hex_sig");
	}

	$tt->store($signature, $depth, $tt_type, $alpha, $best_move);

	return $alpha;
}

sub quiesce {
	my ($self, $ply, $alpha, $beta, $pline, $is_pv) = @_;

	if ($self->{nodes} >= $self->{nodes_to_tc}) {
		$self->checkTime;
	}

	$self->{seldepth} = cp_max($ply, $self->{seldepth});

	my @line;
	my $position = $self->{position};

	if (DEBUG) {
		my $hex_signature = sprintf '%016x', $position->signature;
		$self->indent($ply, "quiescence: alpha = $alpha, beta = $beta,"
			. " sig: $hex_signature $position");
		if ($is_pv) {
			$self->indent($ply, "in PV");
		}
	}

	# Expand the search, when in check.
	if (cp_pos_in_check($position)) {
		if (DEBUG) {
			$self->indent($ply, "quiescence check extension");
		}
		return $self->alphabeta($ply, 1, $alpha, $beta, $pline, 0);
	}

	my $tt = $self->{tt};
	my $signature = cp_pos_signature $position;
	my $tt_move;
	if (DEBUG) {
		my $hex_sig = sprintf '%016x', $signature;
		$self->indent($ply, "quiescence TT probe $hex_sig \@depth 0, alpha = $alpha, beta = $beta");
	}
	my $tt_value = $tt->probe($signature, 0, $alpha, $beta, \$tt_move);
	if (DEBUG) {
		if ($tt_move) {
			my $cn = $position->moveCoordinateNotation($tt_move);
			$self->indent($ply, "best move: $cn");
		}
	}

	if (defined $tt_value) {
		if (DEBUG) {
			my $hex_sig = sprintf '%016x', $signature;
			$self->indent($ply, "quiescence TT hit for $hex_sig, value $tt_value");
		}
		++$self->{tt_hits};
		return $tt_value;
	}

	my $val = $position->evaluate;
	if ($val >= $beta) {
		if (DEBUG) {
			my $hex_sig = sprintf '%016x', $signature;
			$self->indent($ply, "quiescence standing pat ($val >= $beta), store $val(EXACT) \@depth 0 for $hex_sig");
		}
		# FIXME! Is that correct?
		$tt->store($signature, 0,
			Chess::Plisco::Engine::TranspositionTable::TT_SCORE_EXACT(),
			$val, 0
		);
		return $beta;
	}
	if (DEBUG) {
		$self->indent($ply, "static evaluation: $val");
	}

	my $tt_type = Chess::Plisco::Engine::TranspositionTable::TT_SCORE_ALPHA();
	if ($val > $alpha) {
		$alpha = $val;
		# FIXME! Correct?
		$tt_type = Chess::Plisco::Engine::TranspositionTable::TT_SCORE_EXACT();
	}

	my @pseudo_legal = $position->pseudoLegalAttacks;
	my $pos_info = cp_pos_info $position;
	my $her_pieces = $position->[CP_POS_WHITE_PIECES
			+ !cp_pos_to_move($position)];
	my (@moves);
	my $signatures = $self->{signatures};
	my $signature_slot = $self->{history_length} + $ply;
	foreach my $move (@pseudo_legal) {
		my $state = $position->doMove($move) or next;
		$signatures->[$signature_slot] = $position->[CP_POS_SIGNATURE];
		$position->undoMove($state);
		my $see = $position->SEE($move);

		# A marginal difference can occur if bishops and knights have different
		# values.  But we want to ignore that.
		next if $see <= -CP_PAWN_VALUE;

		# FIXME! Do we have a PV move here?
		if ($move == $tt_move) {
			push @moves, MOVE_ORDERING_TT | $move;
		} else {
			push @moves, ($see << 32) | $move;
		}
	}

	my $legal = 0;
	my $tt_type = Chess::Plisco::Engine::TranspositionTable::TT_SCORE_ALPHA();
	my $best_move = 0;
	foreach my $move (sort { $b <=> $a } @moves) {
		my $state = $position->doMove($move);
		if (DEBUG) {
			my $cn = $position->moveCoordinateNotation($move);
			$self->indent($ply, "move $cn: start quiescence search");
		}
		$is_pv = $is_pv && !$legal;
		++$self->{nodes};
		if (DEBUG) {
			$self->indent($ply, "recurse quiescence search");
		}
		$val = -quiesce($self, $ply + 1, -$beta, -$alpha, $pline, $is_pv);
		$position->undoMove($state);
		if ($val >= $beta) {
			if (DEBUG) {
				my $hex_sig = sprintf '%016x', $signature;
				my $cn = $position->moveCoordinateNotation($move);
				$self->indent($ply, "$cn quiescence fail high ($val >= $beta), store $val(BETA) \@depth 0 for $hex_sig");
			}
			$tt->store($signature, 0,
				Chess::Plisco::Engine::TranspositionTable::TT_SCORE_BETA(),
				$val, $move);
			return $beta;
		}
		if ($val > $alpha) {
			if (DEBUG) {
				$self->indent($ply, "raise quiescence alpha to $alpha");
			}
			$alpha = $val;
			@$pline = ($move, @line);
			$tt_type = Chess::Plisco::Engine::TranspositionTable::TT_SCORE_EXACT();
			$best_move = $move;
			if ($is_pv) {
				$self->{score} = $val;
				$self->printPV($pline);
			}
		}
	}

	if (DEBUG) {
		my $hex_sig = sprintf '%016x', $signature;
		my $type;
		if ($tt_type == TT_SCORE_ALPHA) {
			$type = 'ALPHA';
		} else {
			$type = 'EXACT';
		}
		$self->indent($ply, "quiescence returning alpha $alpha, store ($type) \@depth 0 for $hex_sig");
	}

	$tt->store($signature, 0, $tt_type, $val, $best_move);

	return $alpha;
}

sub rootSearch {
	my ($self, $pline) = @_;

	$self->{nodes} = 0;

	my $position = $self->{position};

	my $max_depth = $self->{max_depth} || (MAX_PLY - 1);
	my $depth = $self->{depth} = 0;
	$self->{seldepth} = 0;
	my $score = $self->{score} = 0;

	my @line = @$pline;
	eval {
		while (++$depth <= $max_depth) {
			$self->{depth} = $depth;
			if (DEBUG) {
				$self->debug("Deepening to depth $depth");
			}
			$score = -$self->alphabeta(1, $depth, -INF, +INF, \@line, 1);
			if (DEBUG) {
				$self->debug("Score at depth $depth: $score");
			}
			if (cp_abs($score) > -(MATE + MAX_PLY)) {
				last;
			}
		}
	};
	if ($@) {
		if ($@ ne "PLISCO_ABORTED\n") {
			$self->{info}->(__"Error: exception raised: $@");
		}
	}
	@$pline = @line;
}
# __END_MACROS__

sub printCurrentMove {
	my ($self, $depth, $move, $moveno) = @_;

	no integer;

	my $position = $self->{position};
	my $cn = $position->moveCoordinateNotation($move);
	my $elapsed = int(1000 * tv_interval($self->{start_time}));

	$self->{info}->("depth $depth currmove $cn currmovenumber $moveno"
		. " time $elapsed");
}

sub think {
	my ($self) = @_;

	my $position = $self->{position};
	my @legal = $position->legalMoves;
	if (!@legal) {
		$self->{info}->(__"Error: no legal moves");
		return;
	}

	my @line;

	$self->{thinking} = 1;
	$self->{tt_hits} = 0;

	if ($self->{debug}) {
		$self->{info}->("allocated time: $self->{allocated_time}");
	}

	$self->rootSearch(\@line);

	delete $self->{thinking};

	if (@line) {
		$self->printPV(\@line);
	} else {
		# Search has returned no move.
		$self->{info}->("Error: pick a random move because of search failure.");
		$line[0] = $legal[int rand @legal];
	}

	return $line[0];
}

# Fill the lookup table for the move values.
foreach my $mover (CP_PAWN .. CP_KING) {
	my @piece_values = (
		0,
		CP_PAWN_VALUE,
		CP_KNIGHT_VALUE,
		CP_BISHOP_VALUE,
		CP_ROOK_VALUE,
		CP_QUEEN_VALUE,
	);

	foreach my $victim (CP_NO_PIECE, CP_PAWN .. CP_QUEEN) {
		my $index = ($victim << 6) | ($mover << 3);
		my $value = $victim ? ($piece_values[$victim] - $mover) : 0;
		$move_values[$index] = $value;
		my $key = (CP_PIECE_CHARS->[0]->[$victim] || ' ') . CP_PIECE_CHARS->[0]->[$mover];
		if ($mover == CP_PAWN) {
			foreach my $promote (CP_KNIGHT .. CP_QUEEN) {
				$move_values[$index | $promote]
					= $value + $piece_values[$promote] - CP_PAWN_VALUE;
				my $pc = CP_PIECE_CHARS->[0]->[$promote];
				my $pvalue = $value + $piece_values[$promote] - CP_PAWN_VALUE;
			}
		}
	}
}

1;
