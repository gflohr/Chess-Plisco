#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# This file is heavily inspired by python-chess.

package Chess::Plisco::TableBase::Syzygy;

use strict;
use integer;

use Scalar::Util qw(reftype);
use Locale::TextDomain qw('Chess-Plisco');
use File::Spec;

use Chess::Plisco qw(:all);

use base qw(Exporter);

use constant TBPIECES => 7;
use constant TABLENAME_REGEX => qr/^[KQRBNP]+v[KQRBNP]+\Z/;
use constant PCHR => qw('K', 'Q', 'R', 'B', 'N', 'P');

our @EXPORTS = qw(open_tablebase);

sub new {
	my ($class, $directory, %__options) = @_;

	my %options = (
		loadWdl => 1,
		loadDtz => 1,
		maxFds => 128,
		%__options
	);

	my $self = bless {
		__wdl => {},
		__dtz => {},
	}, $class;

	$self->addDirectory($directory, %options) if defined $directory;

	return $self;
}

sub addDirectory {
	my ($self, $directory, %__options) = @_;

	my %options = (
		loadWdl => 1,
		loadDtz => 1,
		%__options
	);

	$directory = File::Spec->rel2abs($directory);

	opendir my $dh, $directory or return 0;
	my @files = readdir $dh;

	my $num_files = 0;
	my $largest = 0;
	my $smallest = 0;
	foreach my $filename (@files) {
		my $path = File::Spec->catfile($directory, $filename);

		next if $filename !~ /(.*)\.([^.]+)$/;
		my ($tablename, $ext) = ($1, $2);

		if ($self->__isTablename($tablename) && -f $path) {
			if ($options{loadWdl} && 'rtbw' eq $ext) {
				$num_files += $self->__openTable($self->{__wdl}, 'WDL', $path);
			}
			if ($options{loadDtz} && 'rtbz' eq $ext) {
				$num_files += $self->__openTable($self->{__dtz}, 'DTZ', $path);
			}
		}
	}

	# FIXME! Describe better what has been found.
	return $num_files;
}

sub __openTable {
	my ($self, $hashtable, $class, $path) = @_;

	my $name = $path;
	$name =~ s/\.[^.]+$//;
	$name =~ s{.*[/\\]}{};

	my $table = 
	$hashtable->{$name} = {};

	return $self;
}

sub __isTablename {
	my ($self, $name) = @_;

	return (
		$name =~ TABLENAME_REGEX
		&& $name ne 'KvK' && 'K' eq substr $name, 0, 1 && $name =~ /vK/
	);
}

sub largestWdl {
	my ($self) = @_;

	my $max = 0;
	foreach my $table (keys %{$self->{__wdl}}) {
		my $num_pieces = (length $table) - 1;
		$max = $num_pieces if $num_pieces > $max;
	}

	return $max;
}

sub largestDtz {
	my ($self) = @_;

	my $max = 0;
	foreach my $table (keys %{$self->{__dtz}}) {
		my $num_pieces = (length $table) - 1;
		$max = $num_pieces if $num_pieces > $max;
	}

	return $max;
}

sub normalizeTablename {
	my ($self, $name, $mirror) = @_;

	my ($w, $b) = split 'v', $name;
	my $i = 0;
	my %pchr = map { $_ => $i++ } PCHR;
	$w = join '', sort { $pchr{$a} <=> $pchr{$b} } split //, $w;
	$b = join '', sort { $pchr{$a} <=> $pchr{$b} } split //, $b;

	
}

1;

=head1 NAME

Chess::Plisco::TableBase::Syzygy - Perl interface to Syzygy end-game table bases

=head1 SYNOPSIS

    $tb = Chess::Plisco::TableBase::Syzygy->new("./3-4-5");

=head1 DESCRIPTION

The module B<Chess::Plisco::TableBase::Syzygy> allows access to end-game
table bases in Syzygy format.

=head1 CONSTRUCTOR

=over 4

=item B<new PATH>

Initialize the database located at B<PATH>.

Throws an exception in case of an error.

B<PATH> can be a list of directories separated by a colon (':') resp. a
semi-colon ';' for MS-DOS/MS-Windows.

=back

=head1 METHODS

=over 4

=item B<largest>

Returns the maximum number of pieces for which the database can be probed.

A value of 0 means that no table files had been found at the path passsed as an
argument to the constructor.

=back

=head1 COPYRIGHT

Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>.

=head1 SEE ALSO

L<Chess::Plisco>(3pm), fathom(1), perl(1)
