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

$code = "CHI_A_MASK";
is Chess::Position::chi::preprocess($code), "0x8080808080808080", $code;

done_testing;
