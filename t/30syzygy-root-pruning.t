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
use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;
use Chess::Plisco::Engine::Position;
use Chess::Plisco::Tablebase::Syzygy;

use lib 't/lib';

use TreeFactory;

my $tb = Chess::Plisco::Tablebase::Syzygy->new('t/syzygy');
is 4, $tb->largestWdl, 'largest WDL';
is 4, $tb->largestDtz, 'largest DTZ';

my ($pos, @moves, @expect);

my @tests = (
	{
		name => 'black should only choose winning moves',
		fen => '5R2/8/8/8/6K1/8/5k2/4q3 b - - 1 99',
		depth => 1,
		root_moves => ['Kg2', 'Kg1'],
	},
	# In the next positions, Qb1+ has a DTZ of 2, Qe5+ has a DTZ of 6, and
	# all other moves have higher DTZs, draw, or lose. We should only pick
	# moves that can win under the 50-move rule.
	#
	# Only the side to move can claim a draw. The opponent can claim a draw,
	# when they make a move that pushes the halfmove clock to 100. Our current
	# move will increment the halfmove counter by one, the opponent move again.
	# That means, that all positions where the DTZ plus the halfmove counter
	# plus 2 is greater or equal 100, are a draw under the 50-move rule.  If
	# there is at least one move that can avoid that, it should be picked.
	#
	# The first position is a draw under the 50-move-rule. Pick the move(s)
	# with the lowest DTZ possible.
	{
		name => 'KQvKR position HMC 98',
		fen => '1K6/7R/2k5/8/8/8/8/q7 b - - 98 127',
		depth => 1,
		root_moves => ['Qb1+'],
	},
	# Now, when we capture the rook, the halfmove clock will be reset to 0.
	# Again, we can only win with one move.
	{
		name => 'KQvKR position HMC 97',
		fen => '1K6/7R/2k5/8/8/8/8/q7 b - - 97 127',
		depth => 1,
		root_moves => ['Qb1+'],
	},
	# Omit 96 and 95.
	# Still the same.
	{
		name => 'KQvKR position HMC 94',
		fen => '1K6/7R/2k5/8/8/8/8/q7 b - - 94 127',
		depth => 1,
		root_moves => ['Qb1+'],
	},
	# Now Qe5+ would also work.
	{
		name => 'KQvKR position HMC 93',
		fen => '1K6/7R/2k5/8/8/8/8/q7 b - - 93 127',
		depth => 1,
		root_moves => ['Qb1+', 'Qe5+'],
	},
	# Way too late. But still pick the move with the lowest DTZ.
	{
		name => 'KQvKR position HMC 150',
		fen => '1K6/7R/2k5/8/8/8/8/q7 b - - 150 127',
		depth => 1,
		root_moves => ['Qb1+'],
	},
);

foreach my $test (@tests) {
	my $factory = TreeFactory->new(%$test);
	my $tree = $factory->tree;
	$tree->{tb} = $tb;
	$tree->{tb_cardinality} = $tree->{tb_probe_limit} = 4;
	$tree->{tb_50_move_rule} = 1;

	my $position = $tree->{position};
	my @legal = $position->legalMoves;
	my $root_moves = $tree->{root_moves} = {};
	foreach my $move (@legal) {
		$root_moves->{$move} = {
			san => $position->SAN($move),
		};
	}

	$tree->tbRankRootMoves;
	ok $tree->{tb_root_hit}, "$test->{name}: TB hit";

	my @got = sort map { $position->SAN($_) } keys %{$tree->{root_moves}};
	my @wanted = sort @{$test->{root_moves}};

	is_deeply \@got, \@wanted, "$test->{name}: root move pruning";
}

done_testing;
