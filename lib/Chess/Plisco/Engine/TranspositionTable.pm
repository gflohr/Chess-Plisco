#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine::TranspositionTable;

use strict;
use integer;

use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;
use Chess::Plisco::Engine::Tree;

use constant TT_ENTRY_SIZE => 16;

use constant TT_SCORE_EXACT => 0;
use constant TT_SCORE_ALPHA => 1;
use constant TT_SCORE_BETA => 2;

use constant GENERATION_BITS => 3;
use constant GENERATION_DELTA => (1 << (GENERATION_BITS));
use constant GENERATION_CYCLE => 255 + GENERATION_DELTA;
use constant GENERATION_MASK => (0xFF << (GENERATION_BITS)) & 0xFF;

our @EXPORT = qw(TT_SCORE_EXACT TT_SCORE_ALPHA TT_SCORE_BETA);

use base qw(Exporter);

my $generation8 = 0;

sub new {
	my ($class, $size) = @_;

	my $self = [];
	bless $self, $class;

	return $self->resize($size);
}

sub clear {
	my ($self) = @_;

	my $size = @$self;

	$#$self = 0;
	$#$self = $size;

	return $self;
}

sub resize {
	my ($self, $size) = @_;

	$self->clear;
	$#$self = ($size * 1024 * 1024 / TT_ENTRY_SIZE) - 1;

	return $self;
}

sub probe {
	my ($self, $lookup_key, $ply, $depth, $alpha, $beta, $bestmove) = @_;

	# Throw away the highest bit in order to avoid producing negative indices.
	# See https://github.com/gflohr/Chess-Plisco/issues/48
	my $entry = $self->[($lookup_key & 0x7fff_ffff_ffff_ffff) % scalar @$self] or return;

	my ($stored_key, $payload) = @$entry;
	return if $stored_key != $lookup_key;

	my ($edepth, $flags, $value, $move) = unpack 's4', $payload;
	if ($move) {
		$$bestmove = ($move << (CP_MOVE_PROMOTE_OFFSET)) if $move;
	}

	if ($edepth >= $depth) {
		if ($flags == TT_SCORE_EXACT) {
			if ($value == Chess::Plisco::Engine::Tree::MATE) {
				$value = $value + $ply;
			}

			return $value;
		}

		if (($flags == TT_SCORE_ALPHA) && ($value <= $alpha)) {
			return $alpha;
		}

		if (($flags == TT_SCORE_BETA) && ($value >= $beta)) {
			return $beta;
		}
	}

	return;
}

sub store {
	my ($self, $key, $depth, $flags, $value, $move) = @_;

	# Replacement scheme is currently replace-always.  We must make sure that
	# only the significant bits of the best move are stored.
	my $payload = pack 's4', $depth, $flags, $value, cp_move_significant($move) >> CP_MOVE_PROMOTE_OFFSET;

	# Throw away the highest bit in order to avoid producing negative indices.
	# See https://github.com/gflohr/Chess-Plisco/issues/48
	$self->[($key & 0x7fff_ffff_ffff_ffff) % scalar @$self] = [$key, $payload];
}

sub newSearch {
	$generation8 = 0;
}

sub generation {
	return $generation8;
}

sub sfprobe {
	my ($self, $key) = @_;

	
}

1;

__END__

3. Probe logic: mostly right, but subtle issues
3.1 Key check 👍
my $entry = $self->[$lookup_key % scalar @$self] or return;
my ($stored_key, $payload) = @$entry;
return if $stored_key != $lookup_key;


Correct.

3.2 Best move extraction 👍 (with caveat)
if ($move) {
	$$bestmove = ($move << CP_MOVE_PROMOTE_OFFSET);
}


This is fine as long as:

You treat TT moves as ordering hints, not legal truth

You always validate legality before using them

3.3 Depth check 👍
if ($edepth >= $depth) {


Correct.

4. 🚨 Mate score adjustment is wrong

This part is dangerous:

if ($value <= MATE + MAX_PLY) {
	$value += ($edepth - $depth);
} elsif ($value >= -MATE - MAX_PLY) {
	$value -= ($edepth - $depth);
}

Problems:

Sign logic is reversed

Mate distance should be adjusted by ply difference from root, not depth difference

You’re adjusting exact scores only, but you also need to do this consistently on store

Correct principle

If you store mate scores as:

+MATE - ply
-MATE + ply


Then on probe you must rebase them to the current ply, not depth.

Typical approach:

Store scores relative to root ply

Or store raw mate scores and adjust using current_ply

Right now:

You’re mixing search depth with distance-to-mate

That will mis-evaluate mates, especially with re-searches

This is a known engine bug pattern.

5. 🚨 TT + null-window search bug (you already hit this)

You mentioned earlier:

“My null window search is broken… TT_EXACT inside null-window”

And yes — your TT allows that bug.

Why?

In store():

$self->[$key % scalar @$self] = [$key, $payload];


You store EXACT unconditionally, regardless of:

full-window search

null-window search

fail-high / fail-low context

Consequence

Null-window search returns a cutoff

You store TT_SCORE_EXACT

Re-search hits TT and returns immediately

Search collapses incorrectly

Rule (important)

Never store TT_EXACT from a null-window search
unless you later confirm it with a full-window re-search.

Fix

Pass a flag into store():

store($key, $depth, $flags, $value, $move, $is_null_window)


Then:

return if $is_null_window && $flags == TT_SCORE_EXACT;

6. Quiescence interaction ⚠️

You asked earlier:

“Standing pat is exact, right?”

Yes — but only within the quiescence horizon.

Your TT currently:

does not distinguish between:

normal search

quiescence search

stores depth blindly

That means:

Q-search entries can overwrite full-search entries

Or be probed incorrectly

Standard solution

Either:

Do not store quiescence nodes at all

Or store them with a special depth (e.g. depth = 0)

Or keep a separate TT for QS (rare)

Right now: unsafe.

7. Bound logic is mostly correct 👍
if (($flags == TT_SCORE_ALPHA) && ($value <= $alpha)) {
	return $alpha;
}

if (($flags == TT_SCORE_BETA) && ($value >= $beta)) {
	return $beta;
}


This is fine.

Minor nit:

Some engines return $value, not $alpha/$beta

Your version is safe and conservative

8. Replacement scheme: replace-always ⚠️
# Replacement scheme is currently replace-always.


This is okay for now, but:

You’ll lose deep entries to shallow ones

Especially harmful with null-window searches

Later upgrade:

Prefer deeper depth

Or prefer EXACT over bounds

Or two-entry-per-bucket

Not urgent, but worth noting.

9. Minor Perl-level issues

use integer;
Be very careful: this can break mate math and evaluation scaling.

pack 's4'
Limits you to 16-bit scores. That’s tight if:

MATE = 32000

You add ply offsets

% scalar @$self
OK, but power-of-two sizes + bitmasking are faster.

Summary: What I think overall

Good foundation, but currently unsafe for serious search.

Definitely fix these:

❌ resize() ignores $size

❌ EXACT TT entries stored during null-window search

❌ Mate score adjustment logic

❌ Mixing quiescence and normal TT entries

Design-wise:

Fine for experimentation

Will produce subtle search bugs

Explains the null-window issue you saw earlier

If you want, next we can:

Refactor this TT to be null-window safe

Define a clean mate-score convention

Or walk through how Stockfish stores bounds step by step

You’re clearly past the “toy engine” stage — this is now about correctness details, not concepts.