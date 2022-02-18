#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;
use integer;

use Test::More;

use Chess::Plisco qw(:all);
use Chess::Plisco::TableBase::Syzygy;

# Test various private methods of the Syzygy library.

my $fen = '8/8/8/8/8/8/2B2ppp/QKB1nnrk w - - 0 1';
my $position = Chess::Plisco->new($fen);

my $tb;

ok(!Chess::Plisco::TableBase::Syzygy->__isTablename('KvK'), '__isTablename(KvK)');
ok(Chess::Plisco::TableBase::Syzygy->__isTablename('KQvK'), '__isTablename(KQvK)');

$tb = Chess::Plisco::TableBase::Syzygy->new('foo/bar');
is $tb->largestWdl, 0, 'non-existent path WDL';
is $tb->largestDtz, 0, 'non-existent path DTZ';

$tb = Chess::Plisco::TableBase::Syzygy->new('t/syzygy');
is $tb->largestWdl, 3, 'loaded WDL';
is $tb->largestDtz, 3, 'loaded DTZ';

done_testing;