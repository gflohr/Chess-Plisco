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
	my $king_shift_offset = 11 + 6 * $my_color;
	my $king_shift = ($p->[CP_POS_INFO] & (0x3f << $king_shift_offset)) >> $king_shift_offset;
	_cp_pos_attacked $p, $king_shift;
})