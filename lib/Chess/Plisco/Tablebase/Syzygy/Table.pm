#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# This file is heavily inspired by the source code of python-chess.

package Chess::Plisco::Tablebase::Syzygy::Table;

use strict;

sub __new {
	my ($class, $path) = @_;

	my $self = bless {
		__path => $path,
		__initialized => 0,
		__data => undef,
	}, $class;
}

1;

=head1 NAME

Chess::Plisco::TableBase::Syzygy::Table - Syzygy Tables

=head1 SYNOPSIS

    die "Chess::Plisco::TableBase::Syzygy::Table" is an abstract base class.

=head1 DESCRIPTION

The module B<Chess::Plisco::TableBase::Syzygy::Table> is an abstract base class
internally used by L<Chess::Plisco::TableBase::Syzygy>.

=head1 COPYRIGHT

Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>.

=head1 SEE ALSO

L<Chess::Plisco::TableBase::Syzygy>(3pm) L<Chess::Plisco>(3pm), perl(1)
