#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

BEGIN {
	unless ($ENV{AUTHOR_TESTING}) {
		print qq{1..0 # SKIP these tests are for testing by the author\n};
		exit
	}
}

use Test::More;
use Test::Pod::Coverage 1.08;
use Pod::Coverage::TrustPod;

pod_coverage_ok('Chess::Plisco', { coverage_class => 'Pod::Coverage::TrustPod' });
pod_coverage_ok('Chess::Plisco::Macro', {
	coverage_class => 'Pod::Coverage::TrustPod',
	also_private => [qr/^filter$/]
});

done_testing;
