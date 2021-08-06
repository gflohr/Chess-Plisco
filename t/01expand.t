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

# Do not "use" the module because we do not want to activate the source
# filtering.
require Chess::Position::chi;

my ($source, $sdoc, @arguments);

$source = 'chi_move_from($move)';
$sdoc = PPI::Document->new(\$source);
@arguments = Chess::Position::chi::extract_arguments($sdoc, 'chi_move');
is((scalar @arguments), 1);
is $arguments[0]->content, '$move', 'chi_move_from($move)';

$source = 'chi_move_set_from($move, $square)';
$sdoc = PPI::Document->new(\$source);
@arguments = Chess::Position::chi::extract_arguments($sdoc, 'chi_move');
is((scalar @arguments), 2);
is $arguments[0]->content, '$move', 'chi_move_set_from(>$move<, $square)';
is $arguments[1]->content, '$square', 'chi_move_set_from($move, >$square<)';

$source = 'chi_move_set_from($move, chi_coords_to_square("e", "2"))';
$sdoc = PPI::Document->new(\$source);
@arguments = Chess::Position::chi::extract_arguments($sdoc, 'chi_move');
is((scalar @arguments), 2);
is $arguments[0]->content, '$move',
	'chi_move_set_from(>$move<, chi_coords_to_square("e", "2"))';
is $arguments[1]->content, 'chi_coords_to_square("e", "2")',
	'chi_move_set_from($move, >chi_coords_to_square("e", "2")<)';

done_testing;
