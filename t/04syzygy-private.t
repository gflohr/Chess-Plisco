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

use Test::More tests => 8;

use Chess::Plisco qw(:all);
use Chess::Plisco::TableBase::Syzygy;

# Test various private methods of the Syzygy library.

my $fen = '8/8/8/8/8/8/2B2ppp/QKB1nnrk w - - 0 1';
my $position = Chess::Plisco->new($fen);
my $sc = Chess::Plisco::TableBase::Syzygy::SEP_CHAR;

TODO: {
	local $TODO = 'test tablebase files';
	ok !Chess::Plisco::TableBase::Syzygy->new('foo/bar'), 'non-existent path';
};

my $tb = Chess::Plisco::TableBase::Syzygy->new("foo/bar${sc}t/syzygy");
ok $tb, 'loaded';

is $tb->__prtStr($position), 'KQBBvKRNNPPP', "prt_str($fen)";
is $tb->__prtStr($position, 1), 'KRNNPPPvKQBB', "prt_str($fen, 1)";

{
	local $SIG{__WARN__} = sub {};
	ok !$tb->__openTB('not-there', '.rtbw'), 'non-existent file';
	ok $tb->__openTB('corrupt', '.rtbw'), 'existing file';
	ok !$tb->__testTB('corrupt', '.rtbw'), 'corrupt file';
	ok $tb->__testTB('KQvK', '.rtbw'), 'test valid file';
}