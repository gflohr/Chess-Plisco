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

use Chess::Position qw(:all);

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
define cp_pos_kings => '$p', '$p->[CP_POS_KINGS]';
define cp_pos_rooks => '$p', '$p->[CP_POS_ROOKS]';
define cp_pos_bishops => '$p', '$p->[CP_POS_BISHOPS]';
define cp_pos_knights => '$p', '$p->[CP_POS_KNIGHTS]';
define cp_pos_pawns => '$p', '$p->[CP_POS_PAWNS]';
define cp_pos_to_move => '$p', '$p->[CP_POS_TO_MOVE]';
define cp_pos_w_kcastle => '$p', '$p->[CP_POS_W_KCASTLE]';
define cp_pos_w_qcastle => '$p', '$p->[CP_POS_W_QCASTLE]';
define cp_pos_b_kcastle => '$p', '$p->[CP_POS_B_KCASTLE]';
define cp_pos_b_qcastle => '$p', '$p->[CP_POS_B_QCASTLE]';
define cp_pos_ep_shift => '$p', '$p->[CP_POS_EP_SHIFT]';
define cp_pos_half_move_clock => '$p', '$p->[CP_POS_HALF_MOVE_CLOCK]';
define cp_pos_half_moves => '$p', '$p->[CP_POS_HALF_MOVES]';

define cp_move_to => '$m', '(($m) & 0x3f)';
define cp_move_set_to => '$m', '$v', '(($m) = (($m) & ~0x3f) | (($v) & 0x3f))';

# Other macros.
define cp_popcount => '$b', '$c',
		'{ my $_b = $b; for ($c = 0; $_b; ++$c) { $_b &= $_b - 1; } }';
define cp_coords_to_shift => '$f', '$r', '(($r) * 8 + (7 - ($f)))';

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

=head 1 NAME

Chess::Position::Macro - Macros/inline functions for Chess::Position

=head1 SYNOPSIS

    use Chess::Position::Macro;

    my $white_pieces = cp_pos_w_pieces(Chess::Position->new);

    my $bitboard = '0x8080808080808080';
    my $popcount;

    cp_popcount $bitboard, $popcount;
    cp_popcount($bitboard, $popcount); # You can also use parentheses ...

    print "There are $popcount bits set in $bitboard.\n";

=head1 DESCRIPTION

The module L<Chess::Position::Macro> is a source filter.  It makes a number
of macros respectively inline functions available that can be invoked without
any subroutine call overhead.  In fact, all invocations of these macros are
translated into constant expressions at compile-time.

The source filter is probably not perfect but is able to translate at least
the source code of L<Chess::Position>.  If you have trouble like unexpected
syntax errors in your own code, you can use the function C<preprocess()< (see
below), to get a translation of your source file, and find the problem.

Please note that not all translation errors are considered a bug of the
source filter.  If the problem can be avoided by re-formulating your code,
a fix will probably be refused.

You may also think that the biggest bug of this module is its mere existance
because it is a dirty hack.  Welcome to the world of chess programming, where
performance is always more important than beauty or elegance.  And if you
do not like the approach taken here, simply do not use the module.  You can
use L<Chess::Position> without L<Chess::Position::Macro>, only that your code
will maybe become slower, more error-prone, and more likely to break with
future versions of L<Chess::Position>.

=head1 MOTIVATION

Chess programming should be really fast, and in this context the unavoidable
overhead of method or subroutine calls contributes enormously to the execution
time of the software.

In the C programming language, you can use preprocessor macros or inline
functions in order to avoid the calling overhead.  In Perl, this can only
be done for constants with the L<constant> pragma:

    use constant CP_FILE_A => 0;
    use constant CP_SQUARE_E1 => 0x0808080808080808 | 0x00000000000000ff;

These are actually subroutines but Perl inlines them into your code, even
with constant folding (see the second example), so that you pay no price for
the use of these constants.

But L<Chess::Position> needs parametrized macros.  For example, if you want
to extract the start square of a move, you have to do this:

    $from = ((($move) >> 6) & 0x3f);

But it is awkward to remember.  Other computations are even more complicated.
For example to get the number of bits set in a bitboard C<$bb>, you have to
do the following:

    my $_b = $bb;

    for ($popcount = 0; $_b; ++$popcount) {
        $_b &= $_b - 1;
    }

This is a well-known algorithm but you either have to implement it in a function
or method and pay the price of subroutine calls, or you have to repeat it over
and over in your code.

This module tries to mitigate that dilemma. If you just "use" it, all
invocations of the macros defined here, are translated into a regular statements
so that you can do these computations without subroutine call overhead.
Depending on the exact implementation of the macro, you can often use them as
l-vales (the left-hand side of an assignment).  This is mentioned in the
documentation below.

=head1 FUNCTIONS

You should only use one single function of this module, the function
C<preprocess()> that does the actual translation of your code.  Example:

    require Chess::Position::Macro;
    open my $fh, '<', 'YourModule.pm' or die;
    print Chess::Position::Macro::preprocess(join '', <$fh>);

This will dump the translated source code of F<YourModule.pm> on standard
output.

=head1 MACROS

Note that the source filter is theoretically able to inline constants (that
are macros without arguments) as well but this feature is not used because
it does not have any advantage over the regular L<constant> pragma of Perl.

=head2 Macros for L<Chess::Position> Instances

=over 4

=item B<cp_pos_w_pieces(POS)>

Get or set the bitboard for all white pieces from the L<Chess::Position> B<POS>.

L-value: yes.

=item B<cp_pos_b_pieces(POS)>

Get or set the bitboard for all black pieces from the L<Chess::Position> B<POS>.

L-value: yes.

=item B<cp_pos_kings(POS)>

Get or set the bitboard for all kings from the L<Chess::Position> B<POS>.

L-value: yes.

=item B<cp_pos_rooks(POS)>

Get or set the bitboard for all rooks from the L<Chess::Position> B<POS>.

L-value: yes.

=item B<cp_pos_bishops(POS)>

Get or set the bitboard for all bishops from the L<Chess::Position> B<POS>.

L-value: yes.

=item B<cp_pos_knights(POS)>

Get or set the bitboard for all knights from the L<Chess::Position> B<POS>.

L-value: yes.

=item B<cp_pos_pawns(POS)>

Get or set the bitboard for all pawns from the L<Chess::Position> B<POS>.

L-value: yes.

=item B<cp_pos_to_move(POS)>

Get or set the side to move from the L<Chess::Position> B<POS>.

L-value: yes.

=item B<cp_pos_w_kcastle(POS)>

Get or set the king-side castling status for white from the L<Chess::Position> B<POS>.

L-value: yes.

=item B<cp_pos_w_qcastle(POS)>

Get or set the king-side castling status for white from the L<Chess::Position> B<POS>.

L-value: yes.

=item B<cp_pos_b_kcastle(POS)>

Get or set the king-side castling status for black from the L<Chess::Position> B<POS>.

L-value: yes.

=item B<cp_pos_b_qcastle(POS)>

Get or set the king-side castling status for black from the L<Chess::Position> B<POS>.

L-value: yes.

=item B<cp_pos_half_move_clock(POS)>

Get or set the half-move clock from the L<Chess::Position> B<POS>.

L-value: yes.

=item B<cp_pos_half_moves(POS)>

Get or set the number of half-moves from the L<Chess::Position> B<POS>.

L-value: yes.

=back

=head2 Move Macros

These macros operate on scalar moves for L<Chess::Position> which are just
plain integers.  They do I<not> work for instances of a
L<Chess::Position::Move>!

=over 4

=item B<cp_move_to(MOVE)>

Get the destination square of B<MOVE> as a bit-shift offset.

L-value: no.

=item B<cp_move_set_to(MOVE, TO)>

Set the destination square of B<MOVE> as a bit-shift offset to B<TO>.

L-value: no.

=back

=head2 Bit-fiddling Macros

=over 4

=item B<cp_popcount(BITBOARD, COUNT)>

Count the number of bits set in B<BITBOARD> and save it in B<COUNT>.

L-value: no.

=back

=head2 Miscellaneous Macros

=over 4

=item B<cp_coords_to_shift(FILE, RANK)>

Calculate a bit shift offset for the square that B<FILE> (0-7) and B<RANK>
(0-7) point to.

L-value: no.

=back

=head1 COPYRIGHT

Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>.

=head1 SEE ALSO

L<Chess::Position>, L<constant>, L<Filter::Util::Call>, perl(1)