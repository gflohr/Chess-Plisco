#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Tablebase::Syzygy::Table::WDL;

use strict;

use base qw(Chess::Plisco::Tablebase::Syzygy::Table);

sub new {
	my ($class, $path) = @_;

	my $self = $class->SUPER::__new($path);

	return $self;
}

1;

=head1 NAME

Chess::Plisco::TableBase::Syzygy::Table::WDL - Syzygy WDL Tables

=head1 SYNOPSIS

    $table = Chess::Plisco::TableBase::Syzygy::Table::WDL->new("KQvK.rtbw");

=head1 DESCRIPTION

The module B<Chess::Plisco::TableBase::Syzygy::Table::WDL> is a class
internally used by L<Chess::Plisco::TableBase::Syzygy>.  You should not
use it directly.

=head1 CONSTRUCTOR

=over 4

=item B<new PATH>

Initialize the table located at B<PATH>.

=back

=head1 COPYRIGHT

Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>.

=head1 SEE ALSO

L<Chess::Plisco::TableBase::Syzygy>, L<Chess::Plisco>(3pm), perl(1)
