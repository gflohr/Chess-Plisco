#! /usr/bin/env perl

# Copyright (C) 2018 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;
use integer;

use Test::More;

use Chess::Plisco::Engine::TT;
use Chess::Plisco::Engine::Constants;

# Create the default transposition table of 16 MB.
my $tt = Chess::Plisco::Engine::TT->new(16);
ok $tt, "create transposition table";

# The entries are organised into clusters. Each cluster has 40 bytes.
my $num_clusters = int(16 * 1024 * 1024 / 40);

is scalar @$tt, $num_clusters, "$num_clusters clusters";

# Retrieve an entry.
my $signature = 0xbea7ab1e_ba5eba11;
my ($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
	$tt_pv, @write_info) = $tt->probe($signature);

ok !$tt_hit, 'hit in empty table';
ok !$tt_depth, 'depth in empty table';
ok !$tt_move, 'move in empty table';
ok !$tt_value, 'value in empty table';
ok !$tt_eval, 'eval in empty table';
ok !$tt_bound, 'bound in empty table';
ok !$tt_pv, 'PV flag in empty table';

# Store an entry and get the values.
# @write_info, $signature, $value, $pv, $bound, $depth, $move, $eval) = @_;
$tt->store(@write_info, $signature, 314, 1, BOUND_EXACT, 7, 1234, 278);
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
	$tt_pv, @write_info) = $tt->probe($signature);
ok $tt_hit, 'hit on first entry';
is $tt_depth, 7, 'depth in first entry';
is $tt_bound, BOUND_EXACT, 'bound in first entry';
is $tt_move, 1234, 'move in first entry';
is $tt_value, 314, 'value in first entry';
is $tt_eval, 278, 'eval in first entry';

done_testing;
