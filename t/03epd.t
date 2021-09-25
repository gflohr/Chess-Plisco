#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More tests => 2;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Chess::Plisco::EPD;

my $t_dir = dirname abs_path __FILE__;
my $epd_dir = "$t_dir/epd";

eval { Chess::Plisco::EPD->new('not-existing') };
ok $@, 'exception for non-existing file';

my $filename = "$epd_dir/dm1.epd";
my $epd = Chess::Plisco::EPD->new($filename);
ok $epd, 'load epd from file';