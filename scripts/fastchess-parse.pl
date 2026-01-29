#! /usr/bin/env perl

# Copyright (C) 2021-2026 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;
use v5.10;

use Locale::TextDomain qw(Chess-Plisco);
use Getopt::Long;

sub display_usage;
sub usage_error;
sub version_information;
sub list($);
sub extract($$$);

my %options;
Getopt::Long::Configure('bundling');
GetOptions(
	'e|extract=s' => \$options{extract},
	'l|list' => \$options{list},
	'p|player=s' => \$options{player},
	'h|help' => \$options{help},
	'v|version' => \$options{version},
) or usage_error;

display_usage if $options{help};
version_information if $options{version};

usage_error __"One of the options '--list' or '--path' is mandatory!"
    if !$options{list} && !$options{extract};
usage_error __"The options '--list' and '--path' are mutually exclusive!"
    if !$options{list} && !$options{extract};
usage_error __"The option '--player' is mandatory for '--extract'!"
    if $options{extract} && !defined $options{player};
usage_error __"The option '--player' does not make sense with '--list'!"
    if $options{list} && defined $options{player};

usage_error __"Exactly one filename argument must be given!"
	if 1 != @ARGV;

my ($filename) = @ARGV;

if ($options{list}) {
	list $filename;
} else {
	extract $filename, $options{extract}, $options{player};
}

sub list($) {
	my ($filename, $player) = @_;

	open my $fh, '<', $filename
		or die __x("Error opening '{filename}': {error}!\n",
				filename => $filename,
				error => $!);
	
	my %ids;
	my @ids;

	while (my $line = $fh->getline) {
		if ($line =~ /^.+?< *(0x[0-9a-f]+)> (?:<stderr> )?(.+?) (?:<---|--->)/) {
			my ($id, $player) = ($1, $2);
			push @ids, $id if !$ids{$id};

			$ids{$id} //= {
				player_list => [],
				players => {},
			};

			if (!exists $ids{$id}->{players}->{$player}) {
				$ids{$id}->{players}->{$player} = 1;
				push @{$ids{$id}->{player_list}}, $player;
			}
		}
	}

	if (!@ids) {
		die __x"{filename}: no games found!\n", filename => $filename;
	}

	foreach my $id (@ids) {
		my (@players) = @{$ids{$id}->{player_list}};
		if (@players != 2) {
			warn __x("warning: {filename}: id {id}: not exactly two players!\n",
				filename => $filename, id => $id);
			next;
		}

		say "$id: $players[0] vs. $players[1]";
	}
}

sub extract($$$) {
	my ($filename, $id, $player) = @_;

	open my $fh, '<', $filename
		or die __x("Error opening '{filename}': {error}!\n",
				filename => $filename,
				error => $!);
	
	my $count = 0;
	while (my $line = $fh->getline) {
		if ($line =~ /^.+?< *(0x[0-9a-f]+)> (<stderr> )?(.+?) (?:<---) (.+)/) {
			next if $id ne $1;
			next if $2;
			next if $player ne $3;
			my $command = $4;
			++$count;
			say $command;
		}
	}

	die __x("error: {filename}: {id}: no commands found for player {player}!\n",
			filename => $filename, id => $id, player => $player)
		if !$count;
}

sub display_usage {
	print __x(<<EOF, program => $0);
Usage: {program} [OPTIONS] LOGFILE

Extract UCI commands from a fastchess logfile.
EOF

	print "\n";

	print __(<<'EOF');
Mandatory arguments to long options, are mandatory to short options, too.
EOF

	print "\n";

	print __"Mode of operation:\n";
	print __(<<EOF);
  -e, --extract=ID             extract game ID from FILENAME
  -l, --list                   list game IDs from FILENAME
EOF

	print "\n";

	print __"Choice of colour:\n";
	print __(<<'EOF');
  -c, --colour=COLOUR, --color=COLOR extract game for colour COLOUR
EOF

	print "\n";

	print __"Informative output:\n";

	print __(<<EOF);
  -h, --help                   display this help and exit
EOF
	print __(<<EOF);
  -V, --version                display version information and exit
EOF

	exit 0;
}

sub usage_error {
	my ($msg) = @_;

	$msg = '' if !defined $msg;
	$msg =~ s/^[ \t]+//;
	$msg =~ s/[ \t\r\n]+$//;

	if (length $msg) {
		$msg = __x("{program}: {error}\n",
		           program => $0, error => $msg);
	}

	die $msg . __x("Try '{program} --help' for more information!\n",
	               program => $0);
}

sub version_information {
	my $package = 'Chess::Plisco';
	my $version = $Chess::Plisco::VERION || __"development version";

	print __x(<<EOF, program => $0, package => $package, version => $version);
{program} ({package}) {version}
Copyright (C) 2021-2026 Guido Flohr <guido.flohr\@cantanea.com>.
License: WTFPL2 <http://www.wtfpl.net/>
This program is free software. It comes without any warranty, to
the extent permitted by applicable law.
EOF
}

1;
