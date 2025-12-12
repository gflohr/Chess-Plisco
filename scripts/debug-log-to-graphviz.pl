#! /usr/bin/env perl

use strict;

use Chess::Plisco;

sub getLine;
sub processPosition;

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
	subnodes => [],
};

my $value = processPosition $pos, $tree;

use Data::Dumper;
warn Dumper $tree;

if (!defined $value) {
	die "search not terminated";
}

print <<"EOF";
Digraph AlphaBetaTree {
	node[shape=circle, fontsize=8]
	root[]
EOF

print <<"EOF";

	root[label="root v=$value\\nα=-∞ β=+∞"];
}
EOF

sub processPosition {
	my ($pos, $tree) = @_;

	while (my %line = getLine) {
		if ($line{type} eq 'finished') {
			return $line{value};
		} elsif ($line{type} eq 'start') {
			my $move = $line{move};
			my $subtree = { move => $move, subnodes => []};

			$subtree->{value} = processPosition $pos, $subtree;

			push @{$tree->{subnodes}}, $subtree;
		} elsif ($line{type} eq 'value') {
			return $line{value};
		} elsif ($line{type} eq 'score') {
			return $line{value};
		}
	}
}

sub getLine {
	my $line = $fh->getline or die "premature end-of-file";

	chomp $line;
	my $original = $line;
	die "unrecognised line: $line" if $line !~ s/^DEBUG //;

	if ($line =~ /^Score at depth $depth: (-[0-9]+)$/) {
		$DB::single = 1;
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
	);

	if ($line =~ /^move ([a-h][1-8][a-h][1-8][qrbn]?): start search$/) {
		return %retval, type => 'start', move => $1;
	} elsif ($line =~ /^move ([a-h][1-8][a-h][1-8][qrbn]?): value (-?[0-9]+)$/) {
		return %retval, type => 'value', move => $1, value => $2;
	} elsif ($line =~ /^quiescence standing pat \((-?[0-9]+)/) {
		return %retval, type => 'score', value => $1, standing_pat => 1;
	} elsif ($line =~ /^quiescence returning alpha (-?[0-9]+)/) {
		return %retval, type => 'score', value => $1, return_alpha => 1;
	}

	return %retval, unrecognised => $line;
}
