#! /usr/bin/env perl

# Copyright (C) 2018 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Make Dist::Zilla happy.
# ABSTRACT: Analyze chess games in PGN format

use strict;

use Test::More;

use Chess::Plisco::Engine::TT;

# Create the default transposition table of 16 MB.
my $tt = Chess::Plisco::Engine::TT->new(16);
ok $tt, "create transposition table";

# The entries are organised into clusters. Each cluster has 40 bytes.
my $num_clusters = int(16 * 1024 * 1024 / 40);

is scalar @$tt, $num_clusters, "$num_clusters clusters";

done_testing;
