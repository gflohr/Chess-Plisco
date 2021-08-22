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
use Data::Dumper;
use Chess::Position qw(:all);
use Chess::Position::Macro;
use Chess::Position::Move;

my ($pos, $move, $undo_info, @moves);

$pos = Chess::Position->new;
$move = Chess::Position::Move->new('g1h3', $pos)->toInteger;
ok $pos->doMove($move), '1. Nh3';
my @plm = $pos->pseudoLegalMoves;
$move = Chess::Position::Move->new('h7h6', $pos)->toInteger;
die $move;
$undo_info = $pos->doMove($move), '1. ...h6';
ok $undo_info, '1. ...h6';
ok $pos->[CP_POS_PAWNS] & (CP_H_MASK & CP_6_MASK),
	'1. ...h6, pawn should be on h6';
diag $pos->dumpBitboard($pos->[CP_POS_PAWNS]);
diag $pos->dumpBitboard($pos->[CP_POS_KNIGHTS]);
ok $pos->undoMove($move, $undo_info);
ok $pos->[CP_POS_PAWNS] & (CP_H_MASK & CP_6_MASK),
	'undo 1. ...h6, pawn should be back on h7';
diag $pos->dumpBitboard($pos->[CP_POS_PAWNS]);
diag $pos->dumpBitboard($pos->[CP_POS_KNIGHTS]);

done_testing;
