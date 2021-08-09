#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More;
use Chess::Position::Macro;

my ($bitboard, $count);

$bitboard = 0x88;
cp_popcount $bitboard, $count;
is $count, 2, 'popcount 0x88';
is $bitboard, 0x88, 'popcount 0x88';

$bitboard = 0xffff_ffff_ffff_ffff;
cp_popcount $bitboard, $count;
is $count, 64, 'popcount 0xffff_ffff_ffff_ffff';
is $bitboard, 0xffff_ffff_ffff_ffff, 'popcount 0xffff_ffff_ffff_ffff';

done_testing;
