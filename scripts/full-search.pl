#! /usr/bin/env perl

use strict;
use v5.10;

use List::Util qw(max min);

use Chess::Plisco::Engine::Position;
use Chess::Plisco::Engine::Constants;
use Chess::Plisco::Macro;

sub search;
sub qsearch;
sub print_line;

my ($depth, @fen) = @ARGV;

if (!$depth || $depth < 1 || $depth >> MAX_PLY) {
	warn "Usage: $0 DEPTH [FEN]\n\n";

	warn "Do a complete search to depth DEPTH and output the evaluation for\n";
	warn "every single position.\n";
	exit 1;
}

say 'Value,Best,Line';

my $fen = join ' ', @fen;
my $pos = Chess::Plisco::Engine::Position->new($fen);

search $pos, $depth, 0, !$pos->turn;

sub search {
	my ($pos, $depth, $ply, $maximising, @line) = @_;

	if ($depth <= 0) {
		return qsearch $pos, $ply, $maximising, @line;
	}

	my @moves = $pos->legalMoves;

	if (!@moves) {
		my $value = $pos->inCheck ? -MATE + $ply : 0;
		print_line $pos, $value, 1, @line;

		return $value;
	}

	my @values;
	my @backup = @$pos;
	foreach my $move (@moves) {
		my $cn = $pos->moveCoordinateNotation($move);
		$pos->move($move);
		my $value = search $pos, $depth - 1, $ply + 1, !$maximising, @line, $cn;
		push @values, $value;
		@$pos = @backup;
	}

	my $best_value = $maximising ? max(@values) : min(@values);

	print_line $pos, $best_value, 1, @line;

	return $best_value;
}

sub qsearch {
	my ($pos, $ply, $maximising, @line) = @_;

	if ($pos->inCheck) {
		return search $pos, 1, $ply, $maximising, @line;
	}

	my @moves = $pos->legalMoves;

	# Evaluate always returns the evaluation from white's view.
	my $value = $ply & 1 ? -$pos->evaluate : $pos->evaluate;
	print_line $pos, $value, 0, @line;

	my @backup = @$pos;
	my @values = ($value);
	foreach my $move (@moves) {
		next if !(cp_move_captured($move) || cp_move_promote($move));

		my $cn = $pos->moveCoordinateNotation($move);
		$pos->move($move);
		my $value = qsearch $pos, $ply + 1, !$maximising, @line, $cn;
		push @values, $value;
		@$pos = @backup;
	}

	my $best_value = $maximising ? max(@values) : min(@values);

	print_line $pos, $best_value, 1, @line;

	return $best_value;
}

sub print_line {
	my ($pos, $value, $is_best, @line) = @_;

	my $line = join ' ', @line;
	$is_best = $is_best ? 'best' : '';
	say join ',', $value, $is_best, $line;
}