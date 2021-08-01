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

sub new {
	my ($class) = @_;

	my $self = {
		w_pieces => 0x1234,
	};
	bless $self, $class;
}

1;
