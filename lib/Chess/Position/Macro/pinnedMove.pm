#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# This is a macro that is not intended to run standalone.

( do {
	my $to_move = cp_pos_to_move $self;
	my $kso = 11 + 6 * $to_move;
	my $king_shift = (cp_pos_info($self) & (0x3f << $kso)) >> $kso;
	my $pinned;

	# If the piece to move is on a common line with the king, it may be pinned.
	my $king_ray = $common_lines[$from]->[$king_shift];
	if ($king_ray) {
		my ($is_rook, $ray_mask) = @$king_ray;

		my $to = cp_move_to $move;
		my $to_mask = 1 << $to;

		# If the destination square is on the same line, the piece cannot be
		# pinned.  That also covers the case that the piece that moves captures
		# the piece that pins.
		if (!($to_mask & $ray_mask)) {
			my $my_pieces = $self->[$to_move];
			my $her_pieces = $self->[!$to_move];
			my $occupancy = $my_pieces | $her_pieces;
			my $empty = ~$occupancy;

			if ($is_rook) {
				$pinned = cp_mm_rmagic($from, $occupancy)
					& $ray_mask & ($empty | $her_pieces) & cp_pos_rooks($self);
			} else {
				$pinned = cp_mm_bmagic($from, $occupancy)
					& $ray_mask & ($empty | $her_pieces) & cp_pos_bishops($self);
			}
		}
	}

	$pinned;
})
