#! /usr/bin/env perl

use strict;

use Chess::Plisco;

sub getLine;
sub processPosition;
sub getNode;
sub printDot;

my ($filename, $depth) = @ARGV;

if (!defined $depth || $depth !~ /^[1-9][0-9]*$/) {
	die "Usage: $0 LOGFILE DEPTH\n";
}

open my $fh, '<', $filename or die "$filename: $!";

# Scan to depth.
my $found;
while (my $line = $fh->getline) {
	if ($line eq "DEBUG Deepening to depth $depth\n") {
		$found = 1;
		last;
	}
}

die "no output for depth $depth found" if !$found;

my @ab;
my @value;

my $pos = Chess::Plisco->new('8/8/2p5/4K2k/8/8/8/8 w - - 0 61');
my $tree = {
	moves => [],
	subnodes => {},
};

my $value = processPosition $pos, $tree;

if (!defined $value) {
	die "search not terminated";
}

$tree->{value} = $value;

use Data::Dumper;
warn Dumper $tree;

print <<"EOF";
Digraph AlphaBetaTree {
	node[shape=circle, fontsize=8]
	n[]
EOF

printDot $tree, $pos;

print <<"EOF";

	n[label="root v=$value\\nα=-∞ β=+∞"];
}
EOF

sub processPosition {
	my ($pos, $tree) = @_;

	my @moves;

	while (my %line = getLine) {
		if ($line{type} eq 'finished') {
			return $line{value};
		} elsif ($line{type} eq 'start') {
			my $move = $line{move};
			push @moves, $move;
		} elsif ($line{type} eq 'value') {
			my $node = getNode(\@moves, $tree);
			$node->{value} = $line{value};
			pop @moves;
		#} elsif ($line{type} eq 'score') {
		#	return $line{value};
		}
	}
}

sub getLine {
	my $line = $fh->getline or die "premature end-of-file";

	chomp $line;
	my $original = $line;
	die "unrecognised line: $line" if $line !~ s/^DEBUG //;

	if ($line =~ /^Score at depth $depth: (-[0-9]+)$/) {
		return type => 'finished', value => $1 ;
	}

	#if (!($line =~ s{^\[([0-9]+)/([0-9]+)\] }{})) {
	if (!($line =~ s{^\[([0-9]+)/([0-9]+)\] }{}m)) { # The m is only here to make VS Code happy.
		die "unrecognised line: $line";
	}

	$line =~ s/\.+//;

	my %retval = (
		ply => $1,
		seldepth => $2,
		type => 'unknown',
		original => $original,
	);

	if ($line =~ /^move ([a-h][1-8][a-h][1-8][qrbn]?): start search$/) {
		return %retval, type => 'start', move => $1;
	} elsif ($line =~ /^move ([a-h][1-8][a-h][1-8][qrbn]?): value (-?[0-9]+)$/) {
		return %retval, type => 'value', move => $1, value => $2;
	#} elsif ($line =~ /^quiescence standing pat \((-?[0-9]+)/) {
	#	return %retval, type => 'score', value => $1, standing_pat => 1;
	#} elsif ($line =~ /^quiescence returning alpha (-?[0-9]+)/) {
	#	return %retval, type => 'score', value => $1, return_alpha => 1;
	}

	return %retval, unrecognised => $line;
}

sub getNode {
	my ($moves, $tree) = @_;

	my $node = $tree;

	foreach my $move (@$moves) {
		if (!$node->{subnodes}->{$move}) {
			push @{$node->{moves}}, $move;
			$node->{subnodes}->{$move} //= {
				moves => [],
				subnodes => {},
			};
		}
		$node = $node->{subnodes}->{$move};
	}

	return $node;
}

sub printDot {
	my ($tree, $pos, @path) = @_;

	my $parent_suffix = join '_', @path;

	my $i = 0;
	foreach my $move (@{$tree->{moves}}) {
		++$i;
		my $suffix = join '_', @path, $i;
		my $san = $pos->SAN($pos->parseMove($move));
		my $subtree = $tree->{subnodes}->{$move};

		print qq{\tn${suffix}[label="v=$subtree->{value}"];\n};
		print qq{\tn$parent_suffix -> n${suffix}[label="$san"];\n};

		my $undo = $pos->doMove($move);

		printDot $subtree, $pos, @path, $i;

		$pos->undoMove($undo);
	}
}