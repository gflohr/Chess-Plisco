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
sub preprocess;
sub extract_arguments;
sub split_arguments;
sub expand;
sub expand_placeholders;
sub expand_placeholder;

my %defines;

define cp_pos_w_pieces => '$p', '$p->[CP_POS_W_PIECES]';
define cp_pos_b_pieces => '$p', '$p->[CP_POS_B_PIECES]';
define cp_pos_pawns => '$p', '$p->[CP_POS_PAWNS]';
define cp_pos_knights => '$p', '$p->[CP_POS_KNIGHTS]';
define cp_pos_bishops => '$p', '$p->[CP_POS_BISHOPS]';
define cp_pos_rooks => '$p', '$p->[CP_POS_ROOKS]';
define cp_pos_kings => '$p', '$p->[CP_POS_KINGS]';
define cp_pos_half_move_clock => '$p', '$p->[CP_POS_HALF_MOVE_CLOCK]';
define cp_pos_in_check => '$p', '$p->[CP_POS_IN_CHECK]';
define cp_pos_half_moves => '$p', '$p->[CP_POS_HALF_MOVES]';
define cp_pos_info => '$p', '$p->[CP_POS_INFO]';
define cp_pos_castling => '$p', '$p->[CP_POS_INFO] & 0xf';
define cp_pos_w_ks_castle => '$p', '$p->[CP_POS_INFO] & (1 << 0)';
define cp_pos_w_qs_castle => '$p', '$p->[CP_POS_INFO] & (1 << 1)';
define cp_pos_b_ks_castle => '$p', '$p->[CP_POS_INFO] & (1 << 2)';
define cp_pos_b_qs_castle => '$p', '$p->[CP_POS_INFO] & (1 << 3)';
define cp_pos_to_move => '$p', '(($p->[CP_POS_INFO] & (1 << 4)) >> 4)';
define cp_pos_ep_shift => '$p', '$p->[CP_POS_EP_SHIFT]';
define cp_pos_w_king_shift => '$p', '$p->[CP_POS_W_KING_SHIFT]';
define cp_pos_b_king_shift => '$p', '$p->[CP_POS_B_KING_SHIFT]';

define cp_pos_set_castling => '$p', '$c',
	'($p->[CP_POS_INFO] = ($p->[CP_POS_INFO] & ~0x7) | $c)';
define cp_pos_set_w_ks_castling => '$p', '$c',
	'($p->[CP_POS_INFO] = ($p->[CP_POS_INFO] & ~0x1) | ($c << 0))';
define cp_pos_set_w_qs_castling => '$p', '$c',
	'($p->[CP_POS_INFO] = ($p->[CP_POS_INFO] & ~0x2) | ($c << 1))';
define cp_pos_set_b_ks_castling => '$p', '$c',
	'($p->[CP_POS_INFO] = ($p->[CP_POS_INFO] & ~0x4) | ($c << 2))';
define cp_pos_set_b_qs_castling => '$p', '$c',
	'($p->[CP_POS_INFO] = ($p->[CP_POS_INFO] & ~0x8) | ($c << 3))';
define cp_pos_set_to_move => '$p', '$c',
	'($p->[CP_POS_INFO] = ($p->[CP_POS_INFO] & ~0x10) | ($c << 4))';

define _cp_pos_checkers => '$p', '(do {'
	. 'my $my_color = cp_pos_to_move($p); '
	. 'my $her_color = !$my_color; '
	. 'my $my_pieces = $p->[CP_POS_W_PIECES + $my_color]; '
	. 'my $her_pieces = $p->[CP_POS_W_PIECES + $her_color]; '
	. 'my $occupancy = $my_pieces | $her_pieces; '
	. 'my $empty = ~$occupancy; '
	. 'my $king_shift = $p->[CP_POS_W_KING_SHIFT + $my_color]; '
	. '$her_pieces '
	. '	& (($pawn_masks[$my_color]->[2]->[$king_shift] & cp_pos_pawns($self)) '
	. '	| ($knight_attack_masks[$king_shift] & cp_pos_knights($self)) '
	. '	| (cp_mm_bmagic($king_shift, $occupancy) & cp_pos_bishops($self)) '
	. '	| (cp_mm_rmagic($king_shift, $occupancy) & cp_pos_rooks($self)));'
	. '}) ';

define cp_move_to => '$m', '(($m) & 0x3f)';
define cp_move_set_to => '$m', '$v', '(($m) = (($m) & ~0x3f) | (($v) & 0x3f))';
define cp_move_from => '$m', '(($m >> 6) & 0x3f)';
define cp_move_set_from => '$m', '$v', '(($m) = (($m) & ~0xfc0) | (($v) & 0x3f) << 6)';
define cp_move_promote => '$m', '(($m >> 12) & 0x7)';
define cp_move_set_promote => '$m', '$p', '(($m) = (($m) & ~0x7000) | (($p) & 0x7) << 12)';
define cp_move_attacker => '$m', '(($m >> 15) & 0x7)';
define cp_move_set_attacker => '$m', '$a', '(($m) = (($m) & ~0x38000) | (($a) & 0x7) << 15)';
define cp_move_coordinate_notation => '$m', 'cp_shift_to_square(cp_move_from $m) . cp_shift_to_square(cp_move_to $m) . CP_PIECE_CHARS->[CP_BLACK]->[cp_move_promote $m]';

# Bitboard macros.
define cp_bb_popcount => '$b', '$c',
		'{ my $_b = $b; for ($c = 0; $_b; ++$c) { $_b &= $_b - 1; } }';
define cp_bb_clear_but_least_set => '$b', '(($b) & -($b))';
define cp_bb_count_trailing_zbits => '$bb', '(do {'
	. 'my $A = $bb - 1 - ((($bb - 1) >> 1) & 0x5555_5555_5555_5555);'
	. 'my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);'
	. 'my $n = $C + ($C >> 32);'
	. '$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);'
	. '$n = ($n & 0xffff) + ($n >> 16);'
	. '$n = ($n & 0xff) + ($n >> 8);'
	. '})';
define cp_bb_clear_least_set => '$bb', '(($bb) & (($bb) - 1))';

# Magic moves.
define cp_mm_bmagic => '$s', '$o',
	'CP_MAGICMOVESBDB->[$s][(((($o) & CP_MAGICMOVES_B_MASK->[$s]) * CP_MAGICMOVES_B_MAGICS->[$s]) >> 55) & ((1 << (64 - 55)) - 1)]';
define cp_mm_rmagic => '$s', '$o',
	'CP_MAGICMOVESRDB->[$s][(((($o) & CP_MAGICMOVES_R_MASK->[$s]) * CP_MAGICMOVES_R_MAGICS->[$s]) >> 52) & ((1 << (64 - 52)) - 1)]';

# Conversion between different notions of a square.
define cp_coords_to_shift => '$f', '$r', '(($r) * 8 + (7 - ($f)))';
define cp_shift_to_coords => '$s', '(7 - $s & 0x7, $s >> 3)';
define cp_coords_to_square => '$f', '$r', 'chr(97 + $f) . (1 + $r)';
define cp_square_to_coords => '$s', '(ord($s) - 97, -1 + substr $s, 1)';
define cp_square_to_shift => '$s', '(((substr $s, 1) - 1) << 3) + 104 - ord($s)';
define cp_shift_to_square => '$s', 'chr(97 + ((7 - $s) & 0x7)) . (1 + ($s >> 3))';

define _cp_moves_from_mask => '$t', '@m', '$b', 'while ($target_mask) {'
		. 'push @m, $b | cp_bb_count_trailing_zbits cp_bb_clear_but_least_set $t;'
		. '$target_mask = cp_bb_clear_least_set $target_mask;'
		. '}';

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
		$self->{__source} .= $_;
		$_ = '';
	} elsif ($status == 0) {
		$_ = preprocess $self->{__source};
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
	if (!$definition->{code}) {
		use Data::Dumper;
		warn "$name: ", Dumper $definition;
	}
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

	foreach my $token (@arglist) {
		# We have to clone the token, in case it had been used before.
		$token = $token->clone;
	}

	foreach my $token (@arglist, @tail) {
		$parent->add_element($token);
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

	my $code_doc = PPI::Document->new(\$code);
	if (!$code_doc) {
		require Carp;
		my $msg = $@->message;
		Carp::croak("cannot parse code for '$name': $msg\n");
	}

	$defines{$name} = {
		args => [@args],
		code => $code_doc,
	};

	return;
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
