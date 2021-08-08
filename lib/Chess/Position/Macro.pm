#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Position::Macro;

use strict;

use Filter::Util::Call;
use PPI::Document;

sub define;
sub extract_arguments;
sub split_arguments;
sub expand;
sub expand_placeholders;
sub expand_placeholder;

my %defines;

define cp_move_to => '$m', '(($m) & 0x3f)';
define cp_move_set_to => '$m', '$v', '(($m) = (($m) & ~0x3f) | (($v) & 0x3f))';

define cp_coords_to_shift => '$f', '$r', '(($r) * 8 + (7 - ($f)))';

# FIXME! These can be made constants.  No need to go through the source filter
# because Perl inlines them anyway.
define CP_A_MASK => 0x8080808080808080;
define CP_B_MASK => 0x4040404040404040;
define CP_C_MASK => 0x2020202020202020;
define CP_D_MASK => 0x1010101010101010;
define CP_E_MASK => 0x0808080808080808;
define CP_F_MASK => 0x0404040404040404;
define CP_G_MASK => 0x0202020202020202;
define CP_H_MASK => 0x0101010101010101;

define CP_1_MASK => 0x00000000000000ff;
define CP_2_MASK => 0x000000000000ff00;
define CP_3_MASK => 0x0000000000ff0000;
define CP_4_MASK => 0x00000000ff000000;
define CP_5_MASK => 0x000000ff00000000;
define CP_6_MASK => 0x0000ff0000000000;
define CP_7_MASK => 0x00ff000000000000;
define CP_8_MASK => 0xff00000000000000;

define CP_FILE_A => (0);
define CP_FILE_B => (1);
define CP_FILE_C => (2);
define CP_FILE_D => (3);
define CP_FILE_E => (4);
define CP_FILE_F => (5);
define CP_FILE_G => (6);
define CP_FILE_H => (7);

define CP_RANK_1 => (0);
define CP_RANK_2 => (1);
define CP_RANK_3 => (2);
define CP_RANK_4 => (3);
define CP_RANK_5 => (4);
define CP_RANK_6 => (5);
define CP_RANK_7 => (6);
define CP_RANK_8 => (7);

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
		s/(CP_[_A-Z0-9]+)/eval $1/ge;

		# And then macros.  That doesn't work ... :(
		s/(cp_[_a-z0-9]+[ \t]*\(.*?\))/eval $1/ge;

		$self->{__source} .= $_;
		$_ = '';
	} elsif ($status == 0) {
		$_ = $self->{__source};
		$self->{__eof} = 1;
		return 1;
	}

	return $status;
}

sub expand {
	my ($parent, $invocation) = @_;

	# First find the invocation.
	my @siblings = $parent->children;
	my $count = -1;
	my $idx;
	foreach my $sibling (@siblings) {
		++$count;
		if ($sibling == $invocation) {
			$idx = $count;
			last;
		}
	}

	return if !defined $idx;

	# First remove all elements following the invocation, and later re-add
	# them.
	my $name = $invocation->content;

	my $definition = $defines{$name};
	my $cdoc = $definition->{code}->clone;
	my $cut = 0;
	if (@{$definition->{args}} == 0) {
		# Just a constant, no arguments.
		# Check whether there is a list following, and discard it.
		my $to;
		foreach ($to = $idx + 1; $to < @siblings; ++$to) {
			last if $siblings[$to]->significant;
		}
		if ($to < @siblings && $siblings[$to]->isa('PPI::Structure::List')) {
			$cut = $to - $idx;
		}
	} else {
		my @arguments = extract_arguments $invocation;
		my @placeholders = @{$definition->{args}};
		my %placeholders;
		for (my $i = 0; $i < @placeholders; ++$i) {
			my $placeholder = $placeholders[$i];
			if ($i > $#arguments) {
				$placeholders{$placeholder} = [];
			} else {
				$placeholders{$placeholder} = $arguments[$i];
			}
		}
		expand_placeholders $cdoc, %placeholders;

		my ($to, $first_significant);
		foreach ($to = $idx + 1; $to < @siblings; ++$to) {
			if (!defined $first_significant && $siblings[$to]->significant) {
				$first_significant = $siblings[$to];
				if ($first_significant->isa('PPI::Structure::List')) {
					--$to;
					last;
				}
			}
		}
		$to = $idx if $to >= @siblings;
		$cut = $to - $idx + 1;
	}

	$parent->remove_child($invocation);

	my @tail;
	for (my $i = $idx + 1; $i < @siblings; ++$i) {
		push @tail, $parent->remove_child($siblings[$i]);
	}

	splice @tail, 0, $cut;

	my @children = $cdoc->children;
	foreach my $child (@children) {
		$cdoc->remove_child($child);
	}


	foreach my $sibling (@children, @tail) {
		$parent->add_element($sibling);
	}

	return $invocation;
}

sub expand_placeholders {
	my ($doc, %placeholders) = @_;

	my $words = $doc->find(sub { 
		($_[1]->isa('PPI::Token::Symbol') || $_[1]->isa('PPI::Token::Word'))
		&& exists $placeholders{$_[1]->content} 
	});

	foreach my $word (@$words) {
		expand_placeholder $word, @{$placeholders{$word->content}};
	}
}

sub expand_placeholder {
	my ($word, @arglist) = @_;

	# Find the word in the parent.
	my $parent = $word->parent;
	my $idx;

	my @siblings = $parent->children;
	my $word_idx;
	my @tail;
	for (my $i = 0; $i < @siblings; ++$i) {
		if (defined $word_idx) {
			my $sibling = $siblings[$i];
			$parent->remove_child($sibling);
			push @tail, $sibling;
		} elsif ($siblings[$i] == $word) {
			$word_idx = $i;
			$parent->remove_child($word);
		}
	}

	foreach my $token (@arglist, @tail) {
		# We have to clone the token, in case it had been used before.
		$parent->add_element($token->clone);
	}
}

sub preprocess {
	my ($code) = @_;

	my $source = PPI::Document->new(\$code);

	# We always replace the last macro invocation only, and then re-scan the
	# document. This should ensure that nested macro invocations will work.
	while (1) {
		my $invocations = $source->find(sub {
			$_[1]->isa('PPI::Token::Word') && exists $defines{$_[1]->content}
		});

		last if !$invocations;

		my $invocation = $invocations->[-1];
		my $parent = $invocation->parent;

		expand $parent, $invocation;
	}

	return $source->content;
}

sub define {
	my ($name, @args) = @_;

	my $code = pop @args;
	$code = '' if !defined $code;

	if (exists $defines{$name}) {
		require Carp;
		Carp::croak("duplicate macro definition '$name'");
	}

	$defines{$name} = {
		args => [@args],
		code => PPI::Document->new(\$code),
	}
}

sub extract_arguments {
	my ($word) = @_;

	my $parent = $word->parent;
	my @siblings = $parent->children;
	my $pos;
	for (my $i = 0; $i < @siblings; ++$i) {
		if ($siblings[$i] == $word) {
			$pos = $i;
			last;
		}
	}

	return if !defined $pos;

	# No arguments?
	return if $pos == $#siblings;

	# Skip insignicant tokens.
	my $argidx;
	for (my $i = $pos + 1; $i < @siblings; ++$i) {
		if ($siblings[$i]->significant) {
			$argidx = $i;
			last;
		}
	}

	return if !defined $argidx;

	my @argnodes;
	my $argnodes_parent = $parent;

	if ($siblings[$argidx]->isa('PPI::Token::Structure')) {
		# No arguments.
		return;
	} elsif ($siblings[$argidx]->isa('PPI::Structure::List')) {
		# Call with parentheses.  The only child should be an expression.
		my @expression = $siblings[$argidx]->children;
		return if @expression != 1;
		$argnodes_parent = $expression[0];
		return if !$argnodes_parent->isa('PPI::Statement::Expression');
		@argnodes = $argnodes_parent->children;
	} else {
		for (my $i = $argidx; $i < @siblings; ++$i) {
			# Call without parentheses.
			if ($siblings[$i]->isa('PPI::Token::Structure')
			    && ';' eq $siblings[$i]->content) {
					last;
			}

			push @argnodes, $siblings[$i];
		}
	}

	return split_arguments $argnodes_parent, @argnodes;
}

sub split_arguments {
	my ($parent, @argnodes) = @_;

	my @arguments;
	my @argument;

	for (my $i = 0; $i < @argnodes; ++$i) {
		my $argnode = $argnodes[$i];

		$parent->remove_child($argnode);

		if ($argnode->isa('PPI::Token::Operator')
		    && ',' eq $argnode->content) {
			push @arguments, [@argument];
			undef @argument;
		} else {
			push @argument, $argnode;
		}
	}
	push @arguments, [@argument] if @argument;

	foreach my $argument (@arguments) {
		while (!$argument->[0]->significant) {
			shift @$argument;
		}
		while (!$argument->[-1]->significant) {
			pop @$argument;
		}
	}

	return @arguments;
}

1;
