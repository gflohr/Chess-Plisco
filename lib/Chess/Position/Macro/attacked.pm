#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# This is a macro that is not intended to run standalone.

(do {
	my $my_color = cp_pos_to_move($p);
	my $her_color = !$my_color;
	my $my_pieces = $p->[CP_POS_W_PIECES + $my_color];
	my $her_pieces = $p->[CP_POS_W_PIECES + $her_color];
	my $occupancy = $my_pieces | $her_pieces;
	my $empty = ~$occupancy;
	my $king_shift_offset = 11 + 6 * $my_color;
	my $king_shift = ($p->[CP_POS_INFO] & (0x3f << $king_shift_offset)) >> $king_shift_offset;
	$her_pieces
		& (($pawn_masks[$my_color]->[2]->[$shift] & cp_pos_pawns($p))
			| ($knight_attack_masks[$shift] & cp_pos_knights($p))
			| (cp_mm_bmagic($shift, $occupancy) & cp_pos_bishops($p))
			| (cp_mm_rmagic($shift, $occupancy) & cp_pos_rooks($p)));
});
