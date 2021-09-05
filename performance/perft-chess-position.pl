#! /usr/bin/env perl

use strict;
use integer;
use v5.10;

use lib '../lib';
use Chess::Position qw(:all);

use constant COPY => 1;

my ($depth, @fen) = @ARGV;

die "usage: DEPTH[, FEN]" if (!$depth || $depth !~ /^[1-9][0-9]*/);

my $fen = join ' ', @fen;
my @moves = qw();

autoflush STDOUT, 1;

my $pos = Chess::Position->new($fen);
foreach my $move (@moves) {
	$pos->doMove($pos->parseMove($move));
}

if (COPY) {
	$pos->perftPositionWithOutput($pos, $depth, \*STDOUT);
} else {
	$pos->perftWithOutput($depth, \*STDOUT);
}

my $uci = "UCI equivalent:\nposition ";
$uci .= $fen ? "fen $fen " : 'startpos ';

if (@moves) {
	$uci .= 'moves ' . join ' ', @moves;
}

$uci .= "\ngo perft $depth\n";

print $uci;
