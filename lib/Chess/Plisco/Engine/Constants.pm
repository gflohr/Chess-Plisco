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
use constant DEPTH_ENTRY_OFFSET => -3;

use constant BOUND_NONE => 0;
use constant BOUND_UPPER => 1;
use constant BOUND_LOWER => 2;
use constant BOUND_EXACT => 3;

use constant MATE => -15000;
use constant INF => 16383;
use constant NONE => INF + 1;
use constant MAX_PLY => 512;
use constant DRAW => 0;

use constant PV_NODE => 0;
use constant CUT_NODE => 1;
use constant ALL_NODE => 2;

# Indices into TT probe results.
#
# Boolean flag for a hit.
use constant TT_ENTRY_OCCUPIED => 0;
# The depth of the entry.
use constant TT_ENTRY_DEPTH => 1;
# The best move.
use constant TT_ENTRY_MOVE => 2;
# Value and static evaluation.
use constant TT_ENTRY_VALUE => 3;
use constant TT_ENTRY_EVAL => 4;
# Bound type.
use constant TT_ENTRY_BOUND_TYPE => 5;
# Flag for PV nodes.
use constant TT_ENTRY_PV => 6;
# The index into the TT array.
use constant TT_CLUSTER_INDEX => 7;
# The index of the bucket inside the cluster.
use constant TT_BUCKET_INDEX => 8;
# The current bucket.
use constant TT_BUCKET => 9;

our @EXPORT = qw(
	DEPTH_UNSEARCHED DEPTH_ENTRY_OFFSET
	BOUND_NONE BOUND_UPPER BOUND_LOWER BOUND_EXACT
	MATE INF MAX_PLY DRAW
	PV_NODE CUT_NODE ALL_NODE
);

1;
