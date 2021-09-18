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

my ($pos, @moves, @expect);

my @tests = (
	{
		name => 'Lone white king moves',
		fen => '7k/8/8/8/8/8/8/K7 w - - 0 1',
		san => 'Kb1',
	},
	{
		name => 'Lone black king moves',
		fen => '7k/8/8/8/8/8/8/K7 b - - 0 1',
		san => 'Kg8',
	},
	{
		name => 'Start position 1. e4',
		san => 'e4',
	},
	{
		name => 'Remove ep shift after 1. e4',
		fen => 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
		san => 'Nf6',
	},
	{
		name => 'White queen-side castling',
		fen => '7k/8/8/8/8/8/8/R3K3 w Q - 0 1',
		san => 'O-O-O',
	},
	{
		name => 'Black king captures rook',
		fen => '7k/6R1/8/8/8/8/8/4K3 b - - 0 1',
		san => 'Kxg7',
	},
	{
		name => 'White promotes to queen',
		fen => '7k/4P3/8/8/8/8/8/4K3 w - - 0 1',
		san => 'e8=Q',
	},
	{
		name => 'White promotes to queen and captures',
		fen => '5q1k/4P3/8/8/8/8/8/4K3 w - - 0 1',
		san => 'exf8=Q',
	},
);

plan tests => 5 * @tests;

foreach my $test (@tests) {
	my $pos = Chess::Position->new($test->{fen});
	my $zk_before = $pos->signature;
	ok defined $zk_before, "$test->{name}: zk defined after move";
	my $move = $pos->parseMove($test->{san});
	ok $move, "$test->{name}: parse $test->{san}";
	ok $pos->doMove($move), "$test->{name}: do $test->{san}";
	my $zk_updated = $pos->signature;
	ok defined $zk_updated, "$test->{name}: zk after move";
	my $fen = $pos->toFEN;
	$pos = Chess::Position->new($fen);
	is $zk_updated, $pos->signature, "$test->{name}: zk updated";
}