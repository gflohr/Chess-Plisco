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
	cp_pos_on_move($self) = CP_WHITE;
	cp_pos_w_kcastle($self) = 1;
	cp_pos_w_qcastle($self) = 1;
	cp_pos_b_kcastle($self) = 1;
	cp_pos_b_qcastle($self) = 1;
	cp_pos_ep_shift($self) = 0;
	cp_pos_half_move_clock($self) = 0;
	cp_pos_half_moves($self) = 0;

	bless $self, $class;
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

	$fen .= (cp_pos_on_move($self) == CP_WHITE) ? ' w ' : ' b ';

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

1;
