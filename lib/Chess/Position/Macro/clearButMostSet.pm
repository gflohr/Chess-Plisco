#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# This is a macro that is not intended to run standalone.

## no critic (TestingAndDebugging::RequireUseStrict)

(do {
	my $B = $bb;
	if ($B & 0x8000_0000_0000_0000 && $B != 0x8000_0000_0000_0000) {
		0x8000_0000_0000_0000;
	} else {
		$B |= $B >> 1;
		$B |= $B >> 2;
		$B |= $B >> 4;
		$B |= $B >> 8;
		$B |= $B >> 16;
		$B |= $B >> 32;
		$B - ($B >> 1);
	}
})
