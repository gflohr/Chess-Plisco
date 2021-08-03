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

# This source filter replaces everything here that starts with CHI_ or chi_.
use Chess::Position::chi;

sub new {
	my ($class) = @_;

	# my $self = {
	# 	w_pieces => CHI_1_MASK | CHI_2_MASK,
	# 	b_pieces => CHI_8_MASK | CHI_7_MASK,
	# 	kings => (CHI_1_MASK | CHI_8_MASK) & CHI_E_MASK,
	# 	rooks => ((CHI_A_MASK | CHI_D_MASK | CHI_H_MASK) & CHI_1_MASK)
	# 		| ((CHI_A_MASK | CHI_D_MASK | CHI_H_MASK) & CHI_8_MASK),
	# 	bishops => ((CHI_C_MASK | CHI_D_MASK | CHI_F_MASK) & CHI_1_MASK)
	# 		| ((CHI_C_MASK | CHI_D_MASK | CHI_F_MASK) & CHI_8_MASK),
	# 	knights => ((CHI_B_MASK | CHI_G_MASK) & CHI_1_MASK)
	# 		| ((CHI_B_MASK | CHI_G_MASK) & CHI_8_MASK),
	# 	pawns => CHI_2_MASK | CHI_7_MASK,
	# };
	my $self = {};
	bless $self, $class;
}

sub toFEN {
	my ($self) = @_;

	return '';

	# my $w_pieces = $self->{w_pieces};
	# my $b_pieces = $self->{b_pieces};
	# my $pieces = $w_pieces | $b_pieces;
	# my $pawns = $self->{pawns};
	# my $bishops = $self->{bishops};
	# my $knights = $self->{knights};
	# my $rooks = $self->{rooks};

	# my $fen = '';

	# for (my $rank = CHI_RANK_8; $rank >= CHI_RANK_1; --$rank) {
	# 	my $empty = 0;
	# 	for (my $file = CHI_FILE_A; $file <= CHI_FILE_H; ++$file) {
	# 		my $shift = $self->coordinatesToShift($file, $rank);
	# 		my $mask = 1 << $shift;

	# 		if ($mask & $pieces) {
	# 			if ($empty) {
	# 				$fen .= $empty;
	# 				$empty = 0;
	# 			}

	# 			if ($mask & $w_pieces) {
	# 				if ($mask & $pawns) {
	# 					$fen .= 'P';
	# 				} elsif ($mask & $knights) {
	# 					$fen .= 'N';
	# 				} elsif ($mask & $bishops) {
	# 					if ($mask & $rooks) {
	# 						$fen .= 'Q';
	# 					} else {
	# 						$fen .= 'B';
	# 					}
	# 				} elsif ($mask & $rooks) {
	# 					$fen .= 'R';
	# 				} else {
	# 					$fen .= 'K';
	# 				}
	# 			} elsif ($mask & $b_pieces) {
	# 				if ($mask & $pawns) {
	# 					$fen .= 'p';
	# 				} elsif ($mask & $knights) {
	# 					$fen .= 'n';
	# 				} elsif ($mask & $bishops) {
	# 					if ($mask & $rooks) {
	# 						$fen .= 'q';
	# 					} else {
	# 						$fen .= 'b';
	# 					}
	# 				} elsif ($mask & $rooks) {
	# 					$fen .= 'r';
	# 				} else {
	# 					$fen .= 'k';
	# 				}
	# 			}
	# 		} else {
	# 			++$empty;
	# 		}

	# 		if ($file == CHI_FILE_H) {
	# 			if ($empty) {
	# 				$fen .= $empty;
	# 				$empty = 0;
	# 			}
	# 			if ($rank != CHI_RANK_1) {
	# 				$fen .= '/';
	# 			}
	# 		}
	# 	}
	# }

	# return $fen;
}

sub coordinatesToShift {
	my ($self, $file, $rank) = @_;

	return $rank * 8 + 7 - $file;
}

1;
