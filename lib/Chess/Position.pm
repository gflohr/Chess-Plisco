#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Make Dist::Zilla happy.
# ABSTRACT: Representation of a chess position with move generator, legality checker etc.

package Chess::Position;

use strict;
use integer;
use overload '""' => sub { shift->toFEN };

use Locale::TextDomain qw('Chess-Position');
use Chess::Position::Macro;

sub new {
	my ($class) = @_;

	my $self = [];
	cp_pos_w_pieces($self) = CP_1_MASK | CP_2_MASK;
	cp_pos_b_pieces($self) = CP_8_MASK | CP_7_MASK,
	cp_pos_kings($self) = (CP_1_MASK | CP_8_MASK) & CP_E_MASK;
	cp_pos_rooks($self) = ((CP_A_MASK | CP_D_MASK | CP_H_MASK) & CP_1_MASK)
			| ((CP_A_MASK | CP_D_MASK | CP_H_MASK) & CP_8_MASK),
	cp_pos_bishops($self) = ((CP_C_MASK | CP_D_MASK | CP_F_MASK) & CP_1_MASK)
			| ((CP_C_MASK | CP_D_MASK | CP_F_MASK) & CP_8_MASK),
	cp_pos_knights($self) = ((CP_B_MASK | CP_G_MASK) & CP_1_MASK)
			| ((CP_B_MASK | CP_G_MASK) & CP_8_MASK),
	cp_pos_pawns($self) = CP_2_MASK | CP_7_MASK,
	cp_pos_to_move($self) = CP_WHITE;
	cp_pos_w_kcastle($self) = 1;
	cp_pos_w_qcastle($self) = 1;
	cp_pos_b_kcastle($self) = 1;
	cp_pos_b_qcastle($self) = 1;
	cp_pos_ep_shift($self) = 0;
	cp_pos_half_move_clock($self) = 0;
	cp_pos_half_moves($self) = 0;

	bless $self, $class;
}

sub newFromFEN {
	my ($class, $fen) = @_;

	my ($pieces, $to_move, $castling, $ep_square, $hmc, $moveno)
			= split /[ \t]+/, $fen;
	$ep_square = '-' if !defined $ep_square;
	$hmc = 0 if !defined $hmc;
	$moveno = 1 if !defined $moveno;

	if (!(defined $pieces && defined $to_move && defined $castling)) {
		die __"Illegal FEN.\n";
	}

	my @ranks = split '/', $pieces;
	die __"Illegal FEN: FEN does not have exactly eight ranks.\n"
		if @ranks != 8;
	
	my $shift = 63;
	my $w_pieces = 0;
	my $b_pieces = 0;
	my $kings = 0;
	my $rooks = 0;
	my $knights = 0;
	my $bishops = 0;
	my $pawns = 0;

	my $shift = 63;
	my $rankno = 7;
	foreach my $rank (@ranks) {
		my @chars = split '', $rank;
		foreach my $char (@chars) {
			if ('1' le $char && '8' ge $char) {
				$shift -= $char;
				next;
			}

			my $mask = 1 << $shift;
			if ('P' eq $char) {
				$w_pieces |= $mask;
				$pawns |= $mask;
			} elsif ('p' eq $char) {
				$b_pieces |= $mask;
				$pawns |= $mask;
			} elsif ('N' eq $char) {
				$w_pieces |= $mask;
				$knights |= $mask;
			} elsif ('n' eq $char) {
				$b_pieces |= $mask;
				$knights |= $mask;
			} elsif ('B' eq $char) {
				$w_pieces |= $mask;
				$bishops |= $mask;
			} elsif ('b' eq $char) {
				$b_pieces |= $mask;
				$bishops |= $mask;
			} elsif ('R' eq $char) {
				$w_pieces |= $mask;
				$rooks |= $mask;
			} elsif ('r' eq $char) {
				$b_pieces |= $mask;
				$rooks |= $mask;
			} elsif ('K' eq $char) {
				$w_pieces |= $mask;
				$kings |= $mask;
			} elsif ('k' eq $char) {
				$b_pieces |= $mask;
				$kings |= $mask;
			} elsif ('Q' eq $char) {
				$w_pieces |= $mask;
				$rooks |= $mask;
				$bishops |= $mask;
			} elsif ('q' eq $char) {
				$b_pieces |= $mask;
				$rooks |= $mask;
				$bishops |= $mask;
			} else {
				die __x("Illegal FEN: Illegal piece/number '{x}'.\n",
						x => $char);
			}
			--$shift;

		}

		if ($rankno-- << 3 != $shift + 1) {
			warn (($rankno + 1) << 3);
			warn $shift + 1;
			die __"Illegal FEN: Corrupt piece string.\n";
		}
	}

	my $self = bless [], $class;

	# FIXME! Consistency checks for number of pieces!
	$self->[CP_POS_W_PIECES] = $w_pieces;
	$self->[CP_POS_B_PIECES] = $b_pieces;
	$self->[CP_POS_KINGS] = $kings;
	$self->[CP_POS_ROOKS] = $rooks;
	$self->[CP_POS_BISHOPS] = $bishops;
	$self->[CP_POS_KNIGHTS] = $knights;
	$self->[CP_POS_PAWNS] = $pawns;

	if ('w' eq lc $to_move) {
		$self->[CP_POS_TO_MOVE] = CP_WHITE;
	} elsif ('b' eq lc $to_move) {
		$self->[CP_POS_TO_MOVE] = CP_BLACK;
	} else {
		die __x"Illegal FEN: Side to move is neither 'w' nor 'b'.\n";
	}

	$self->[CP_POS_W_KCASTLE] = 0;
	$self->[CP_POS_W_QCASTLE] = 0;
	$self->[CP_POS_B_KCASTLE] = 0;
	$self->[CP_POS_B_QCASTLE] = 0;
	if (!length $castling) {
		die __"Illegal FEN: Missing castling state.\n";
	}
	if ($castling !~ /^(?:-|K?Q?k?q?)/) {
		die __x("Illegal FEN: Illegal castling state '{state}'.\n",
				state => $castling);
	}

	if ($castling =~ /K/) {
		$self->[CP_POS_W_KCASTLE] = 1;
	}
	if ($castling =~ /Q/) {
		$self->[CP_POS_W_QCASTLE] = 1;
	}
	if ($castling =~ /k/) {
		$self->[CP_POS_B_KCASTLE] = 1;
	}
	if ($castling =~ /q/) {
		$self->[CP_POS_B_QCASTLE] = 1;
	}

	# FIXME! Correct castling state if king or rook has moved.

	if ('-' eq $ep_square) {
		$self->[CP_POS_EP_SHIFT] = 0;
	} elsif ($self->[CP_POS_TO_MOVE] == CP_WHITE
	         && $ep_square !~ /^[a-h]6$/) {
		die __"Illegal FEN: En passant square must be on 6th rank with white to move.\n";
	} elsif ($self->[CP_POS_TO_MOVE] == CP_BLACK
	         && $ep_square !~ /^[a-h]3$/) {
		die __"Illegal FEN: En passant square must be on 3rd rank with black to move.\n";
	} else {
		$self->[CP_POS_EP_SHIFT] = $self->squareToShift($ep_square);
	}

	# FIXME! Check that there is a pawn of the right color on the 5th/4th
	# rank of the EP square!

	if ($hmc !~ /^0|[1-9][0-9]+$/) {
		die __x("Illegal FEN: Illegal half-move clock '{hmc}'.\n", hmc => $hmc);
	}
	$self->[CP_POS_HALF_MOVE_CLOCK] = $hmc;

	if ($moveno !~ /^[1-9][0-9]*$/) {
		die __x("Illegal FEN: Illegal move number '{num}'.\n", num => $moveno);
	}

	if ($self->[CP_POS_TO_MOVE] == CP_WHITE) {
			$self->[CP_POS_HALF_MOVES] = ($moveno - 1) << 1;
	} else {
			$self->[CP_POS_HALF_MOVES] = (($moveno - 1) << 1) + 1;
	}

	# FIXME! Check that side not to move is not in check.

	return $self;
}

sub toFEN {
	my ($self) = @_;

	my $w_pieces = cp_pos_w_pieces($self);
	my $b_pieces = cp_pos_b_pieces($self);
	my $pieces = $w_pieces | $b_pieces;
	my $pawns = cp_pos_pawns($self);
	my $bishops = cp_pos_bishops($self);
	my $knights = cp_pos_knights($self);
	my $rooks = cp_pos_rooks($self);

	my $fen = '';

	for (my $rank = CP_RANK_8; $rank >= CP_RANK_1; --$rank) {
		my $empty = 0;
		for (my $file = CP_FILE_A; $file <= CP_FILE_H; ++$file) {
			my $shift = $self->coordinatesToShift($file, $rank);
			my $mask = 1 << $shift;

			if ($mask & $pieces) {
				if ($empty) {
					$fen .= $empty;
					$empty = 0;
				}

				if ($mask & $w_pieces) {
					if ($mask & $pawns) {
						$fen .= 'P';
					} elsif ($mask & $knights) {
						$fen .= 'N';
					} elsif ($mask & $bishops) {
						if ($mask & $rooks) {
							$fen .= 'Q';
						} else {
							$fen .= 'B';
						}
					} elsif ($mask & $rooks) {
						$fen .= 'R';
					} else {
						$fen .= 'K';
					}
				} elsif ($mask & $b_pieces) {
					if ($mask & $pawns) {
						$fen .= 'p';
					} elsif ($mask & $knights) {
						$fen .= 'n';
					} elsif ($mask & $bishops) {
						if ($mask & $rooks) {
							$fen .= 'q';
						} else {
							$fen .= 'b';
						}
					} elsif ($mask & $rooks) {
						$fen .= 'r';
					} else {
						$fen .= 'k';
					}
				}
			} else {
				++$empty;
			}

			if ($file == CP_FILE_H) {
				if ($empty) {
					$fen .= $empty;
					$empty = 0;
				}
				if ($rank != CP_RANK_1) {
					$fen .= '/';
				}
			}
		}
	}

	$fen .= (cp_pos_to_move($self) == CP_WHITE) ? ' w ' : ' b ';

	my $w_kcastle = cp_pos_w_kcastle($self) || 0;
	my $w_qcastle = cp_pos_w_kcastle($self) || 0;
	my $b_kcastle = cp_pos_w_kcastle($self) || 0;
	my $b_qcastle = cp_pos_w_kcastle($self) || 0;

	my $castle = '';
	$castle .= 'K' if $w_kcastle;
	$castle .= 'Q' if $w_qcastle;
	$castle .= 'k' if $b_kcastle;
	$castle .= 'q' if $b_qcastle;
	$castle ||= '-';

	$fen .= $castle . ' ';

	if (cp_pos_ep_shift $self) {
		$fen .= $self->shiftToSquare(cp_pos_ep_shift $self);
	} else {
		$fen .= '-';
	}

	$fen .= sprintf ' %u %u', cp_pos_half_move_clock($self),
			1 + (cp_pos_half_moves($self) >> 1);

	return $fen;
}

# Class methods.
sub coordinatesToShift {
	my (undef, $file, $rank) = @_;

	return $rank * 8 + 7 - $file;
}

sub shiftToSquare {
	my (undef, $shift) = @_;

	my $rank = 1 + ($shift >> 3);
	my $file = 7 - ($shift & 0x7);

	return sprintf '%c%u ', $file + ord 'a', $rank;
}

sub squareToShift {
	my ($whatever, $square) = @_;

	if ($square !~ /^([a-h])([1-8])$/) {
		die __x("Illegal square '{square}'.\n", square => $square);
	}

	my $file = ord($1) - ord('a');
	my $rank = $2 - 1;

	return $whatever->coordinatesToShift($file, $rank);
}

1;
