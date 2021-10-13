#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine::InputWatcher;

use strict;

use Locale::TextDomain qw('Chess-Plisco');

sub new {
	my ($class, $fh) = @_;

	$fh->blocking(0)
		or die __x("Cannot make input non-blocking: {error}!\n",
			error => $!);

	$fh->autoflush(1);
	bless {
		__handle => $fh,
	}, $class;
}

sub setBatchMode {
	my ($self, $mode) = @_;

	$self->{__batch_mode} = $mode;

	return $self;
}

sub onInput {
	my ($self, $cb) = @_;

	$self->{__on_input} = $cb;
}

sub onEof {
	my ($self, $cb) = @_;

	$self->{__on_eof} = $cb;

	return $self;
}

sub check {
	my ($self) = @_;

	return if $self->{__batch_mode};

	my $buffer;
	my $bytes_read = $self->{__handle}->sysread($buffer, 8192);

	if (!defined $bytes_read) {
		return;
	} if (0 == $bytes_read) {
		$self->{__on_eof}->() if $self->{__on_eof};
		return;
	} else {
		$self->{__on_input}->($buffer) if $self->{__on_input};
	}
}

1;
