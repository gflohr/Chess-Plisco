#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Position::chi;

use strict;

use Filter::Util::Call;

use constant CHI_A_MASK => 0x8080808080808080;
use constant CHI_B_MASK => 0x4040404040404040;
use constant CHI_C_MASK => 0x2020202020202020;
use constant CHI_D_MASK => 0x1010101010101010;
use constant CHI_E_MASK => 0x0808080808080808;
use constant CHI_F_MASK => 0x0404040404040404;
use constant CHI_G_MASK => 0x0202020202020202;
use constant CHI_H_MASK => 0x0101010101010101;

use constant CHI_1_MASK => 0x00000000000000ff;
use constant CHI_2_MASK => 0x000000000000ff00;
use constant CHI_3_MASK => 0x0000000000ff0000;
use constant CHI_4_MASK => 0x00000000ff000000;
use constant CHI_5_MASK => 0x000000ff00000000;
use constant CHI_6_MASK => 0x0000ff0000000000;
use constant CHI_7_MASK => 0x00ff000000000000;
use constant CHI_8_MASK => 0xff00000000000000;

use constant CHI_FILE_A => (0);
use constant CHI_FILE_B => (1);
use constant CHI_FILE_C => (2);
use constant CHI_FILE_D => (3);
use constant CHI_FILE_E => (4);
use constant CHI_FILE_F => (5);
use constant CHI_FILE_G => (6);
use constant CHI_FILE_H => (7);

use constant CHI_RANK_1 => (0);
use constant CHI_RANK_2 => (1);
use constant CHI_RANK_3 => (2);
use constant CHI_RANK_4 => (3);
use constant CHI_RANK_5 => (4);
use constant CHI_RANK_6 => (5);
use constant CHI_RANK_7 => (6);
use constant CHI_RANK_8 => (7);

sub import {
	my ($type) = @_;

	my $self = {
		__source => '',
		__eof => 0,
	};

	filter_add(bless $self);
}

sub filter {
	my ($self) = @_;

	return 0 if $self->{__eof};

	my $status = filter_read();

	if ($status > 0) {
		# Expand constants.
		s/(CHI_[_A-Z0-9]+)/eval $1/ge;

		# And then macros.  That doesn't work ... :(
		s/(chi_[_a-z0-9]+[ \t]*\(.*?\))/eval $1/ge;

		$self->{__source} .= $_;
		$_ = '';
	} elsif ($status == 0) {
		$_ = $self->{__source};
		$self->{__eof} = 1;
		return 1;
	}

	return $status;
}

1;
