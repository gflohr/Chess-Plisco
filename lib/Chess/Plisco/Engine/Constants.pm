#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine::Constants;

use strict;
use integer;

use base qw(Exporter);

use constant DEPTH_UNSEARCHED => -2;

use constant BOUND_NONE => 0;
use constant BOUND_UPPER => 1;
use constant BOUND_LOWER => 2;
use constant BOUND_EXACT => 3;

our @EXPORT = qw(
	DEPTH_UNSEARCHED
);

1;
