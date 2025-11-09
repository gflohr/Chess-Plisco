#! /usr/bin/env perl

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;
use integer;

use Test::More;

use Chess::Plisco;
use Chess::Plisco::Tablebase::Syzygy;

my $pos = Chess::Plisco->new('8/8/8/5N2/5K2/2kB4/8/8 b - - 0 1');
is (SyzygyTesting->calc_key($pos), 'KBNvK', 'calc_key');

$pos = Chess::Plisco->new;
is(SyzygyTesting->calc_key($pos), 'KQRRBBNNPPPPPPPPvKQRRBBNNPPPPPPPP', 'initial key');
is(SyzygyTesting->calc_key($pos), 'KQRRBBNNPPPPPPPPvKQRRBBNNPPPPPPPP', 'initial key mirrored');

$pos = Chess::Plisco->new('8/8/5k2/8/3K4/2Q5/8/8 w - - 0 1');
is(SyzygyTesting->calc_key($pos), 'KQvK', 'regular key order');
is(SyzygyTesting->calc_key($pos, 1), 'KvKQ', 'mirrored key order');

is(SyzygyTesting->normalise_tablename('PNBRQKvK'), 'KQRBNPvK', 'normalise_tablename');
is(SyzygyTesting->normalise_tablename('PNBRQKvK', 1), 'KvKQRBNP', 'normalise_tablename mirrored');

done_testing;
