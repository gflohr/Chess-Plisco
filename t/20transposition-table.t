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

use Test::More tests => 11;

use Chess::Plisco::Engine::TranspositionTable;

my $tt = Chess::Plisco::Engine::TranspositionTable->new(1);
ok $tt, "create transposition table";

my $key = 0x415C0415C0415C0;
ok !$tt->probe($key), "failed probe on empty table";

$tt->store($key, 5, 7, 2304, 1303);

my $entry = $tt->probe($key);

my ($depth, $flags, $value, $move) = @$entry;

is $depth, 5, "depth 5";
is $flags, 7, "flags 7";
is $value, 2304, "value 2304";
is $move, 1303, "move 1303";

$tt->resize(1);
ok !$tt->probe($key), "table should be empty after resize";

$tt->store($key, 5, 7, 2304, 1303);
ok $tt->probe($key), "store again";

$tt->clear;
ok !$tt->probe($key), "table should be empty after clear";

$tt->store($key, 5, 7, 2304, 1303);
ok $tt->probe($key), "store again";
my $collision = $key % scalar @$tt;
ok !$tt->probe($collision), "type 2 collision";