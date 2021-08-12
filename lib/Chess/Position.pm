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

use base qw(Exporter);

my @export_accessors = qw(
	CP_POS_W_PIECES CP_POS_B_PIECES
	CP_POS_KINGS CP_POS_ROOKS CP_POS_BISHOPS CP_POS_KNIGHTS CP_POS_PAWNS
	CP_POS_TO_MOVE
	CP_POS_W_KCASTLE CP_POS_W_QCASTLE CP_POS_B_KCASTLE CP_POS_B_QCASTLE
	CP_POS_EP_SHIFT CP_POS_HALF_MOVE_CLOCK CP_POS_HALF_MOVES
);

my @export_board = qw(
	CP_FILE_A CP_FILE_B CP_FILE_C CP_FILE_D
	CP_FILE_E CP_FILE_F CP_FILE_G CP_FILE_H
	CP_RANK_1 CP_RANK_2 CP_RANK_3 CP_RANK_4
	CP_RANK_5 CP_RANK_6 CP_RANK_7 CP_RANK_8
	CP_A_MASK CP_B_MASK CP_C_MASK CP_D_MASK
	CP_E_MASK CP_F_MASK CP_G_MASK CP_H_MASK
	CP_1_MASK CP_2_MASK CP_3_MASK CP_4_MASK
	CP_5_MASK CP_6_MASK CP_7_MASK CP_8_MASK
);

my @export_pieces = qw(
	CP_WHITE CP_BLACK
	CP_NO_PIECE CP_PAWN CP_KNIGHT CP_BISHOP CP_ROOK CP_QUEEN CP_KING
	CP_PAWN_VALUE CP_KNIGHT_VALUE CP_BISHOP_VALUE CP_ROOK_VALUE CP_QUEEN_VALUE
	CP_PIECE_CHARS
);

our @EXPORT_OK = (@export_pieces, @export_board, @export_accessors);

our %EXPORT_TAGS = (
	accessors => [@export_accessors],
	pieces => [@export_pieces],
	board => [@export_board],
	all => [@EXPORT_OK],
);

# Accessor indexes.
use constant CP_POS_W_PIECES => 0;
use constant CP_POS_B_PIECES => 1;
use constant CP_POS_KINGS => 2;
use constant CP_POS_ROOKS => 3;
use constant CP_POS_BISHOPS => 4;
use constant CP_POS_KNIGHTS => 5;
use constant CP_POS_PAWNS => 6;
use constant CP_POS_TO_MOVE => 7;
use constant CP_POS_W_KCASTLE => 8;
use constant CP_POS_W_QCASTLE => 9;
use constant CP_POS_B_KCASTLE => 10;
use constant CP_POS_B_QCASTLE => 11;
use constant CP_POS_EP_SHIFT => 12;
use constant CP_POS_HALF_MOVE_CLOCK => 13;
use constant CP_POS_HALF_MOVES => 14;

# Board.
use constant CP_A_MASK => 0x8080808080808080;
use constant CP_B_MASK => 0x4040404040404040;
use constant CP_C_MASK => 0x2020202020202020;
use constant CP_D_MASK => 0x1010101010101010;
use constant CP_E_MASK => 0x0808080808080808;
use constant CP_F_MASK => 0x0404040404040404;
use constant CP_G_MASK => 0x0202020202020202;
use constant CP_H_MASK => 0x0101010101010101;

use constant CP_1_MASK => 0x00000000000000ff;
use constant CP_2_MASK => 0x000000000000ff00;
use constant CP_3_MASK => 0x0000000000ff0000;
use constant CP_4_MASK => 0x00000000ff000000;
use constant CP_5_MASK => 0x000000ff00000000;
use constant CP_6_MASK => 0x0000ff0000000000;
use constant CP_7_MASK => 0x00ff000000000000;
use constant CP_8_MASK => 0xff00000000000000;

use constant CP_FILE_A => (0);
use constant CP_FILE_B => (1);
use constant CP_FILE_C => (2);
use constant CP_FILE_D => (3);
use constant CP_FILE_E => (4);
use constant CP_FILE_F => (5);
use constant CP_FILE_G => (6);
use constant CP_FILE_H => (7);

use constant CP_RANK_1 => (0);
use constant CP_RANK_2 => (1);
use constant CP_RANK_3 => (2);
use constant CP_RANK_4 => (3);
use constant CP_RANK_5 => (4);
use constant CP_RANK_6 => (5);
use constant CP_RANK_7 => (6);
use constant CP_RANK_8 => (7);

# Colors.
use constant CP_WHITE => 0;
use constant CP_BLACK => 1;

# Piece constants.
use constant CP_NO_PIECE => 0;
use constant CP_PAWN => 1;
use constant CP_KNIGHT => 2;
use constant CP_BISHOP => 3;
use constant CP_ROOK => 4;
use constant CP_QUEEN => 5;
use constant CP_KING => 6;
use constant CP_PAWN_VALUE => 100;
use constant CP_KNIGHT_VALUE => 300;
use constant CP_BISHOP_VALUE => 300;
use constant CP_ROOK_VALUE => 500;
use constant CP_QUEEN_VALUE => 900;

use constant CP_PIECE_CHARS => [
	['', 'P', 'N', 'B', 'R', 'Q', 'K'],
	['', 'p', 'n', 'b', 'r', 'q', 'k'],
];

# This arrays map a bit shift offset to bitboards that the corresponding
# piece can attack from that square.  They are filled at compile-time at the
# end of this file.
my @king_attack_masks;
my @knight_attack_masks;

sub new {
	my ($class, $fen) = @_;

	return $class->newFromFEN($fen) if defined $fen && length $fen;

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
		die __"Illegal FEN: Incomplete.\n";
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
			die __x("Illegal FEN: Incomplete or overpopulated rank '{rank}'.\n",
				rank => $rank);
		}
	}

	my $popcount;

	cp_bb_popcount $w_pieces & $kings, $popcount;
	if ($popcount != 1) {
		die __"Illegal FEN: White must have exactly one king.\n";
	}
	cp_bb_popcount $b_pieces & $kings, $popcount;
	if ($popcount != 1) {
		die __"Illegal FEN: Black must have exactly one king.\n";
	}

	my $self = bless [], $class;

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

sub pseudoLegalMoves {
	my ($self) = @_;

	my $my_pieces = $self->[cp_pos_to_move $self];
	my $her_pieces = $self->[!cp_pos_to_move $self];

	# FIXME! $shift -> $from!
	my (@moves, $shift, $target_mask, $base_move);

	# Generate knight moves.
	my $knight_mask = $my_pieces & cp_pos_knights $self;
	while ($knight_mask) {
		my $from = cp_bb_count_trailing_zbits cp_bb_clear_but_least_set $knight_mask;

		$base_move = $from << 6;
	
		$target_mask = ~$my_pieces & $knight_attack_masks[$from];

		# FIXME! This can be made a macro!
		while ($target_mask) {
			my $to = cp_bb_count_trailing_zbits cp_bb_clear_but_least_set $target_mask;
			push @moves, $base_move | $to;

			$target_mask = cp_bb_clear_least_set $target_mask;
		}

		$knight_mask = cp_bb_clear_least_set $knight_mask;
	}

	# Generate king moves.  We take advantage of the fact that there is always
	# exactly one king of each color on the board.  So there is no need for a
	# loop.
	my $king_mask = $my_pieces & cp_pos_kings $self;
	$shift = cp_bb_count_trailing_zbits $king_mask;

	# FIXME! 6 should be a constant!
	$base_move = $shift << 6;

	$target_mask = ~$my_pieces & $king_attack_masks[$shift];
	while ($target_mask) {
		my $to = cp_bb_count_trailing_zbits cp_bb_clear_but_least_set $target_mask;
		push @moves, $base_move | $to;

		$target_mask = cp_bb_clear_least_set $target_mask;
	}

	return @moves;
}

# Class methods.
sub dumpBitboard {
	my (undef, $bitboard) = @_;

	my $output = "  a b c d e f g h\n";
	foreach my $shift (reverse (0 .. 63)) {
		if (($shift & 0x7) == 0x7) {
			$output .= 1 + ($shift >> 3);
		}
		if ($bitboard & 1 << $shift) {
			$output .= ' x';
		} else {
			$output .= ' .';
		}

		if (($shift & 0x7) == 0) {
			$output .= ' ';
			$output .= 1 + ($shift >> 3);
			$output .= "\n";
		}
	}
	$output .= "  a b c d e f g h\n";


	return $output;
}

sub coordinatesToShift {
	my (undef, $file, $rank) = @_;

	return $rank * 8 + 7 - $file;
}

sub shiftToCoordinates {
	my (undef, $shift) = @_;

	my $file = (7 - $shift) & 0x7;
	my $rank = $shift >> 3;

	return $file, $rank;
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

###########################################################################
# Generate attack masks.
###########################################################################

# This would be slightly more efficient in one giant loop but with separate
# loops for each variable, it is easier to understand and maintain.

# King attack masks.
for my $shift (0 .. 63) {
	my ($file, $rank) = shiftToCoordinates undef, $shift;

	my $mask = 0;

	# East.
	$mask |= (1 << ($shift - 1)) if $file < 7;

	# South-east.
	$mask |= (1 << ($shift - 9)) if $file < 7 && $rank > 0;

	# South.
	$mask |= (1 << ($shift - 8)) if              $rank > 0;

	# South-west.
	$mask |= (1 << ($shift - 7)) if $file > 0 && $rank > 0;

	# West.
	$mask |= (1 << ($shift + 1)) if $file > 0;

	# North-west.
	$mask |= (1 << ($shift + 9)) if $file > 0 && $rank < 7;

	# North.
	$mask |= (1 << ($shift + 8)) if              $rank < 7;

	# North-east.
	$mask |= (1 << ($shift + 7)) if $file < 7 && $rank < 7;

	$king_attack_masks[$shift] = $mask;
}

# Knight attack masks.
for my $shift (0 .. 63) {
	my ($file, $rank) = shiftToCoordinates undef, $shift;

	my $mask = 0;

	# North-north-east.
	$mask |= (1 << ($shift + 15)) if $file < 7 && $rank < 6;

	# North-east-east.
	$mask |= (1 << ($shift +  6)) if $file < 6 && $rank < 7;

	# South-east-east.
	$mask |= (1 << ($shift - 10)) if $file < 6 && $rank > 0;

	# South-south-east.
	$mask |= (1 << ($shift - 17)) if $file < 7&&  $rank > 1;

	# South-south-west.
	$mask |= (1 << ($shift - 15)) if $file > 0 && $rank > 1;

	# South-west-west.
	$mask |= (1 << ($shift -  6)) if $file > 1 && $rank > 0;

	# North-west-west.
	$mask |= (1 << ($shift + 10)) if $file > 1 && $rank < 7;

	# North-north-west.
	$mask |= (1 << ($shift + 17)) if $file > 0 && $rank < 6;

	$knight_attack_masks[$shift] = $mask;
}

1;
