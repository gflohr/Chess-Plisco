#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More;
use PPI::Document;

# Do not "use" the module because we do not want to acti
require Chess::Position::chi;

my $source = 'chi_move($move)';
my $sdoc = PPI::Document->new(\$source);
$DB::single = 1;
my @arguments = Chess::Position::chi::extract_arguments($sdoc, 'chi_move');
is((scalar @arguments), 1);

use Scalar::Util qw(blessed);
foreach my $argument (@arguments) {
	my $type = blessed $argument;
	warn "$type: $argument\n";
}

done_testing;
