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
	my $pinned;

	# If the piece to move is on a common line with the king, it may be pinned.
	my $king_ray = $common_lines[$from]->[$ks];
	if ($king_ray) {
		my ($is_rook, $ray_mask) = @$king_ray;

		my $to_mask = 1 << $to;

		# If the destination square is on the same line, the piece cannot be
		# pinned.  That also covers the case that the piece that moves captures
		# the piece that pins.
		#
		# FIXME! Do we really need rmagic/bmagic here?
		if (!($to_mask & $ray_mask)) {
			my $my_pieces = $p->[$to_move];
			my $her_pieces = $p->[!$to_move];
			my $occupancy = $my_pieces | $her_pieces;
			my $empty = ~$occupancy;
			my $my_king_mask = 1 << $ks;

			if ($is_rook) {
				my $rmagic = cp_mm_rmagic($from, $occupancy) & $ray_mask;
				$pinned = ($rmagic & $my_king_mask)
						&& ($rmagic & $her_pieces & cp_pos_rooks($p));
			} else {
				my $bmagic = cp_mm_bmagic($from, $occupancy) & $ray_mask;
				$pinned = ($bmagic & $my_king_mask)
						&& ($bmagic & $her_pieces & cp_pos_bishops($p));
			}
		}
	}

	$pinned;
})
