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

sub define;

my @defines;

define chi_concat => 'a', 'b', <<'EOF';
	a . b
EOF

define CHI_A_MASK => 0x8080808080808080;
define CHI_B_MASK => 0x4040404040404040;
define CHI_C_MASK => 0x2020202020202020;
define CHI_D_MASK => 0x1010101010101010;
define CHI_E_MASK => 0x0808080808080808;
define CHI_F_MASK => 0x0404040404040404;
define CHI_G_MASK => 0x0202020202020202;
define CHI_H_MASK => 0x0101010101010101;

define CHI_1_MASK => 0x00000000000000ff;
define CHI_2_MASK => 0x000000000000ff00;
define CHI_3_MASK => 0x0000000000ff0000;
define CHI_4_MASK => 0x00000000ff000000;
define CHI_5_MASK => 0x000000ff00000000;
define CHI_6_MASK => 0x0000ff0000000000;
define CHI_7_MASK => 0x00ff000000000000;
define CHI_8_MASK => 0xff00000000000000;

define CHI_FILE_A => (0);
define CHI_FILE_B => (1);
define CHI_FILE_C => (2);
define CHI_FILE_D => (3);
define CHI_FILE_E => (4);
define CHI_FILE_F => (5);
define CHI_FILE_G => (6);
define CHI_FILE_H => (7);

define CHI_RANK_1 => (0);
define CHI_RANK_2 => (1);
define CHI_RANK_3 => (2);
define CHI_RANK_4 => (3);
define CHI_RANK_5 => (4);
define CHI_RANK_6 => (5);
define CHI_RANK_7 => (6);
define CHI_RANK_8 => (7);

sub import {
	my ($type) = @_;
die;
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

sub define {
	my ($name, @args) = @_;

	my $code = pop @args;
	$code = '' if !defined $code;

	push @defines, {
		args => @args,
		code => $code,
	}
}

1;
