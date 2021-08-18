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
use Chess::Position qw(:all);
use Chess::Position::Macro;

my $pos = Chess::Position->new;
ok $pos, 'created';
is(cp_pos_w_king_shift($pos), 3, 'initial white');
is(cp_pos_b_king_shift($pos), 59, 'initial black');

$pos = Chess::Position->new('8/8/4k3/5P2/8/8/8/K7 b - - 0 1');
ok $pos, 'created';
is(cp_pos_w_king_shift($pos), 7, 'white king on a1');
is(cp_pos_b_king_shift($pos), 43, 'black king on e6');

done_testing;
