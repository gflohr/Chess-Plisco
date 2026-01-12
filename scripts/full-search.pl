#! /usr/bin/env perl

use strict;
use v5.10;

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

say 'Value, Moves';

my $fen = join '', @fen;
my $pos = Chess::Plisco::Engine::Position->new;

search $pos, $depth, 0;

sub search {
	my ($pos, $depth, $ply, @line) = @_;

	if ($depth <= 0) {
		return qsearch $pos, $ply, @line;
	}

	my @moves = $pos->legalMoves;

	if (!@moves) {
		my $value = $pos->inCheck ? -MATE + $ply : 0;
		print_line $pos, $value, @line;
		return;
	}

	my @backup = @$pos;
	foreach my $move (@moves) {
		my $cn = $pos->moveCoordinateNotation($move);
		$pos->move($move);
		search $pos, $depth - 1, $ply + 1, @line, $cn;
		@$pos = @backup;
	}
}

sub qsearch {
	my ($pos, $ply, @line) = @_;

	if ($pos->inCheck) {
		return search $pos, 1, $ply, @line;
	}

	my @moves = $pos->legalMoves;

	# Evaluate always returns the evaluation from white's view.
	my $value = $ply & 1 ? -$pos->evaluate : $pos->evaluate;
	print_line $pos, $value, @line;

	my @backup = @$pos;
	foreach my $move (@moves) {
		next if !(cp_move_captured($move) || cp_move_promote($move));

		my $cn = $pos->moveCoordinateNotation($move);
		$pos->move($move);
		qsearch $pos, $ply + 1, @line, $cn;
		@$pos = @backup;
	}
}

sub print_line {
	my ($pos, $value, @line) = @_;

	say join ',', $value,  @line;
}