#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine;

use strict;
use integer;

use Chess::Plisco qw(:all);

use Chess::Plisco::Engine::Position;
use Chess::Plisco::Engine::TimeControl;
use Chess::Plisco::Engine::Tree;
use Chess::Plisco::Engine::InputWatcher;
use Chess::Plisco::Engine::TranspositionTable;

# These figures are taken from 
use constant MIN_HASH_SIZE => 1;
use constant DEFAULT_HASH_SIZE => 16;
use constant MAX_HASH_SIZE => 33554432;

use constant UCI_OPTIONS => [
	{
		name => 'Hash',
		type => 'spin',
		default => DEFAULT_HASH_SIZE,
		min => MIN_HASH_SIZE,
		max => MAX_HASH_SIZE,
		callback => '__resizeTranspositionTable',
	},
	{
		name => 'Clear Hash',
		type => 'button',
		callback => '__clearTranspositionTable',
	},
];

my $uci_options = UCI_OPTIONS;
my %uci_options = map { $_->{name} => $_ } @$uci_options;

sub new {
	my ($class) = @_;

	my $self = {
		__position => Chess::Plisco::Engine::Position->new,
		__options => {},
	};

	my $options = UCI_OPTIONS;
	foreach my $option (@$options) {
		$self->{__options}->{$option->{name}} = $option->{default};
	}

	my $tt_size = $self->{__options}->{Hash};
	$self->{__tt} = Chess::Plisco::Engine::TranspositionTable->new($tt_size);

	bless $self, $class;
}

sub uci {
	my ($self, $in, $out) = @_;

	$self->{__out} = $out;
	$self->{__out}->autoflush(1);
	$self->{__watcher} = Chess::Plisco::Engine::InputWatcher->new($in);
	$self->{__watcher}->onInput(sub {
		$self->__onUciInput(@_);
	});
	$self->{__watcher}->onEof(sub {
		$self->__onEof(@_);
	});

	my $version = $Chess::Plisco::Engine::VERSION || 'development version';
	$self->__output(<<"EOF");
Welcome to Plisco $version!

This engine implements the UCI protocol (see
http://wbec-ridderkerk.nl/html/UCIProtocol.html).

Try 'help' for a list of commands!

EOF

	while (1) {
		$self->{__watcher}->check(0.01);
		last if delete $self->{__abort};
	}

	return $self;
}

sub __onEof {
	my ($self, $line) = @_;

	print STDERR "Connection to UI lost.\n";
	$self->{__tree}->{move_now} = 1 if $self->{__tree};
	$self->{__abort} = 1;

	return $self;
}

sub __onUciInput {
	my ($self, $line) = @_;

	$line = $self->__trim($line);
	return $self if !length $line;

	my ($cmd, $args) = split /[ \t]+/, $line, 2;

	my $method = '__onUciCmd' . ucfirst lc $cmd;
	$args = $self->__trim($args);
	if ($self->can($method)) {
		my $stop_if_thinking = $self->$method($args);
		if ($self->{__tree} && $stop_if_thinking) {
			die "PLISCO_ABORTED\n";
		}
	} else {
		$self->{__out}->print("info unknown command '$cmd'\n");
	}

	return $self;
}

sub __onUciCmdGo {
	my ($self, $args) = @_;

	my @args = split /[ \t]+/, $args;

	my %params;

	while (@args) {
		my $arg = lc shift @args;
		if ('searchmoves' eq $arg) {
			my @searchmoves;
			while (@args && $args[0] =~ /^[a-h][1-8][a-h][1-8][qrbn]?$/) {
				push @searchmoves, shift @args;
			}
		} elsif ('ponder' eq $arg || 'infinite' eq $arg) {
			$params{$arg} = 1;
		} elsif ('wtime' eq $arg || 'btime' eq $arg
		         || 'winc' eq $arg || 'binc' eq $arg
		         || 'movestogo' eq $arg || 'depth' eq $arg
		         || 'nodes' eq $arg || 'mate' eq $arg
		         || 'movetime' eq $arg
		         || 'perft' eq $arg) {
			my $val = shift @args;
			$val ||= 0;
			$val = +$val;
			unless ($val) {
				$self->__info("error: argument '$arg' expects an integer > 0");
				return;
			}
			$params{$arg} = $val;
		}
	}

	my $info = sub {
		my ($msg) = @_;
		$self->__output("info $msg");
	};

	if ($params{perft}) {
		$self->{__position}->perftByCopyWithOutput($params{perft},
		                                           $self->{__out});
		return $self;
	}

	my $tree = Chess::Plisco::Engine::Tree->new(
		$self->{__position}->copy,
		$self->{__tt},
		$self->{__watcher},
		$info,
		$self->{__signatures});
	$tree->{debug} = 1 if $self->{__debug};

	my $tc = Chess::Plisco::Engine::TimeControl->new($tree, %params);

	$self->{__tree} = $tree;
	my $bestmove;
	eval {
		$bestmove = $tree->think;
		delete $self->{__tree};
	};
	if ($@) {
		$self->__output("unexpected exception: $@");
	}
	if ($bestmove) {
		my $cn = $self->{__position}->moveCoordinateNotation($bestmove);
		$self->__output("bestmove $cn");
	}

	return $self;
}

sub __onUciCmdUcinewgame {
	my ($self) = @_;

	$self->{__tt}->clear;

	return $self;
}

sub __onUciCmdSetoption {
	my ($self, $args) = @_;

	if ($args !~ /^name[ \t]+(.*?)(?:value[ \t]+(.*))?$/) {
		$self->__output("info ERROR: usage setoption name NAME[ value VALUE]");
		return $self;
	}

	my ($name, $value) = map { $self->__trim($_) } ($1, $2);
	if (!exists $uci_options{$name}) {
		$self->__output("info ERROR: unsupported option '$name'");
		return $self;
	}

	my $option = $uci_options{$name};

	if (exists $option->{min}) {
		my $min = $option->{min};
		if (($value || 0) < $min) {
			$self->__output("info ERROR: minimum value for '$name' is $min");
			return $self;
		}
	}

	if (exists $option->{max}) {
		my $max = $option->{max};
		if (($value || 0) > $max) {
			$self->__output("info ERROR: maximum value for '$name' is $max");
			return $self;
		}
	}

	$self->{__options}->{$name} = $value;

	if (exists $option->{callback}) {
		my $method = $option->{callback};
		$self->$method($value);
	}

	return $self;
}

sub __resizeTranspositionTable {
	my ($self, $size) = @_;

	$self->{__tt}->resize($size);
}

sub __clearTranspositionTable {
	my ($self, $size) = @_;

	$self->{__tt}->clear;
}

sub __onUciCmdStop {
	my ($self) = @_;

	# Ignored. Any valid command will terminate the search.

	return $self;
}

sub __onUciCmdPosition {
	my ($self, $args) = @_;

$DB::single = 1;
	unless (defined $args && length $args) {
		$self->__info("error: usage: position FEN POSITION | startpos [MOVES...]");
		return;
	}

	my ($type, @moves) = split /[ \t]+/, $args;
	my $position;
	if ('fen' eq lc $type) {
		my $fen = shift @moves;
		unless (defined $fen && length $fen) {
			$self->__info("error: position missing after 'fen'");
			return;
		}
		while (@moves) {
			if ('moves' eq $moves[0]) {
				last;
			}
			$fen .= ' ' . shift @moves;
		}
		eval {
			$position = Chess::Plisco::Engine::Position->new($fen);
		};
		if ($@) {
			$self->__info("error: invalid FEN string: $@");
			return;
		}
	} elsif ('startpos' eq lc $type) {
		$position = Chess::Plisco::Engine::Position->new;
	} else {
		$self->__info("error: usage: position FEN POSITION | startpos moves [MOVES...]");
		return;
	}

	$self->{__moves} = [];
	my @signatures = ($position->signature);
	if ('moves' eq shift @moves) {
		foreach my $move (@moves) {
			my $status = $position->applyMove($move);
			if (!$status) {
				$self->__info("error: invalid or illegal move '$move'");
				return;
			}
			push @signatures, $position->signature;
		}
	}

	$self->{__position} = $position;
	$self->{__signatures} = \@signatures;

	return $self;
}

sub __onUciCmdHelp {
	my ($self) = @_;

	$self->__output(<<"EOF");
    The Plisco Chess Engine

    The engine understands the following commands:

        uci - switch to UCI mode (no-op)
        debug (on|off) - switch debugging on or off
        go [depth, wtime, btime, ... see protocol!]
        go perft DEPTH - do performance test (blocks engine, hit CTRL-C ...)
        setoption name NAME[ value VALUE] - set option NAME to VALUE
        isready - ping the engine
        stop - move immediately
        help - show available commands
        quit - quit the engine immediately

    See http://wbec-ridderkerk.nl/html/UCIProtocol.html for more information!
EOF

	return;
}

sub __onUciCmdQuit {
	my ($self) = @_;

	$self->{__abort} = 1;

	return $self;
}

sub __onUciCmdUci {
	my ($self) = @_;

	my $version = $Chess::Plisco::Engine::VERSION || 'development version';
	$self->__output("id Plisco $version");
	$self->__output("id author Guido Flohr <guido.flohr\@cantanea.com>");

	my $options = UCI_OPTIONS;
	foreach my $option (@{$options}) {
		my $output = "option name $option->{name} type $option->{type}";
		$output .= " default $option->{default}" if exists $option->{default};
		$output .= " min $option->{min}" if exists $option->{min};
		$output .= " max $option->{max}" if exists $option->{max};
		$self->__output($output);
	}

	$self->__output("uciok");

	return;
}

sub __onUciCmdIsready {
	my ($self) = @_;

	$self->__output("readyok");

	return;
}

sub __onUciCmdDebug {
	my ($self, $onoff) = @_;

	$onoff = '' if !defined $onoff;

	if ('on' eq lc $onoff) {
		$self->{__debug} = 1;
	} elsif ('off' eq lc $onoff) {
		undef $self->{__debug};
	} else {
		$self->__info("usage debug on|off");
	}

	return;
}

sub __output {
	my ($self, $msg) = @_;

	chomp $msg;

	$self->{__out}->print("$msg\n");

	return $self;
}

sub __info {
	my ($self, $msg) = @_;

	return $self->__output("info $msg");
}

sub __debug {
	my ($self, $msg) = @_;

	return $self->__info("debug $msg");
}

sub __trim {
	my ($self, $what) = @_;

	$what =~ s/^[ \t]+//;
	$what =~ s/[ \t\r\n]+$//;

	return $what;
}

1;
