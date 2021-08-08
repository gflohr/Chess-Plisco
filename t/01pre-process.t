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

# Do not "use" the module because we do not want to acti
require Chess::Position::chi;

my ($code);

$code = 'CHI_A_MASK';
is Chess::Position::chi::preprocess($code), 0x8080808080808080, $code;

$code = 'CHI_A_MASK()';
is Chess::Position::chi::preprocess($code), 0x8080808080808080, $code;

$code = 'CHI_A_MASK ()';
is Chess::Position::chi::preprocess($code), 0x8080808080808080, $code;

$code = 'CHI_A_MASK ($what, $ever, nested(subroutine($sth, $else)))';
is Chess::Position::chi::preprocess($code), 0x8080808080808080, $code;

$code = 'my $something = CHI_A_MASK + CHI_B_MASK - 2304; say "goodbye";';
my $expect = 'my $something = 9259542123273814144 + 4629771061636907072 - 2304; say "goodbye";';
is Chess::Position::chi::preprocess($code), $expect, $code;

$code = 'chi_move_to($move)';
is Chess::Position::chi::preprocess($code), '(($move) & 0x3f)', $code;

$code = 'chi_move_to $move';
is Chess::Position::chi::preprocess($code), '(($move) & 0x3f)', $code;

$code = 'chi_move_to($move); return;';
is Chess::Position::chi::preprocess($code), '(($move) & 0x3f); return;', $code;

$code = 'chi_move_to $move; return;';
is Chess::Position::chi::preprocess($code), '(($move) & 0x3f); return;', $code;

$code = 'chi_move_set_to($move, 32);';
is Chess::Position::chi::preprocess($code), '(($move) = (($move) & ~0x3f) | ((32) & 0x3f));', $code;

done_testing;
