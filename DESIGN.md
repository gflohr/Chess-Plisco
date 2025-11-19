# Design

For version 1, a number of design errors will be fixed.

- [Design](#design)
	- [General](#general)
		- [Separate Core Library from Game Play](#separate-core-library-from-game-play)
		- [Limits](#limits)
			- [Maximum Game Length](#maximum-game-length)
			- [Maximum Ply](#maximum-ply)
		- [Compress State Information](#compress-state-information)
		- [Precompute Lookup Tables](#precompute-lookup-tables)
		- [Use Maximum Two Lookup Tables for Features](#use-maximum-two-lookup-tables-for-features)
		- [Use Pawns as Piece Values](#use-pawns-as-piece-values)
		- [Prepare Chess Variants](#prepare-chess-variants)
	- [Data Layout](#data-layout)
		- [Position](#position)
			- [Changes](#changes)
			- [64-Bit Fields](#64-bit-fields)
			- [Bit Fields](#bit-fields)
				- [Turn (1 bit)](#turn-1-bit)
				- [En-Passant File (3 bits)](#en-passant-file-3-bits)
				- [Castling Rights (2 bits)](#castling-rights-2-bits)
				- [Halfmove Clock (22 bits)](#halfmove-clock-22-bits)
				- [Engine: Check Evasion Squares (3 bits)](#engine-check-evasion-squares-3-bits)
				- [Engine: Check Source Squares (12 bits)](#engine-check-source-squares-12-bits)
				- [Engine: Raw Material Balance (7 bits)](#engine-raw-material-balance-7-bits)
		- [Move](#move)
	- [Move Generation](#move-generation)
		- [New API (`move/unmove`)](#new-api-moveunmove)
	- [Engine](#engine)
		- [Commandline Arguments](#commandline-arguments)
		- [Time Management](#time-management)
		- [Evaluation Experiments](#evaluation-experiments)
			- [Encourage Castling](#encourage-castling)
			- [Bishop Pair](#bishop-pair)
			- [Poisoned Pawn](#poisoned-pawn)
			- [Encourage Exchange of Pieces](#encourage-exchange-of-pieces)


## General

### Separate Core Library from Game Play

We currently maintain a lot of information that is not relevant for the core
functionality of the library. Examples:

* location of pieces giving check
* evasion squares (where the king can escape to)
* reversible clock

Computing this slows down the move generator. Instead, for regular library
users, the check information can be computed on the fly.  The reversible
clock can only be updated in game play, when the game history is known.
Therefore, it should be moved there.

### Limits

#### Maximum Game Length

Under the 50-move rule, the maximum game length is less than 6000, under the
75-move rule it is less than 9000.  Therefore, the number of moves can fit
into 16 bits (65535 moves, or 65536 if zero-based).

#### Maximum Ply

The longest line for forcing mate is currently 549, which would be 1098 half
moves. That would fits into 22 bits. So the maximum ply will be limited to
2048.

### Compress State Information

We can reduce the space used here and there.

### Precompute Lookup Tables

Currently, we compute a lot of tables at runtime, when the library is loaded.
That doesn't really save memory and is slow.

### Use Maximum Two Lookup Tables for Features

Some of our lookup tables use moves as an index, others the square shift,
maybe others a piece type.

That should be changed so that at most two tables are generated. One is for
the core library, one for the engine. The idea is that we need just one
lookup per ply.

### Use Pawns as Piece Values

We currently use centipawns so that we can assign slightly higher value to knights and bishops. That costs a lot of space and is not necessary for the core library.

### Prepare Chess Variants

In Perl, that can easily be done by Inheritance. One variant that should be
easy to implement is Chess960 (FischerRandomChess).

## Data Layout

### Position

#### Changes

The check information and reversible clock are removed.

#### 64-Bit Fields

Core Library:

* move count (in Perl no need to limit that to 16 bits)
* pawns bitboard
* knights bitboard
* bishops bitboard
* rooks bitboard
* queens bitboards
* white pieces bitboard
* black pieces bitboard

Engine:

* signature (zobrist key)

#### Bit Fields

The reversible move clock is removed because it is not necessary for the
core library.

##### Turn (1 bit)

As before, 0 for white, 1 for black.

##### En-Passant File (3 bits)

We currently store the shift (6 bits) but is sufficient to store the file:

	ep_shift = 16 + turn * 24 + ep_file

There are 3 ranks between white's en-passant squares and black's en-passant
squares. That is why the multiplication with the turn (0 or 1) works.

##### Castling Rights (2 bits)

No change to previous version.

##### Halfmove Clock (22 bits)

This is only 22 bits. There is no need to put that into a bitboard of its own.

##### Engine: Check Evasion Squares (3 bits)

This used to be 64 buts but can be dramatically reduced. The king can move to
at most 8 squares. We can always encode these eight squares into a 3-bit
bitmask relative to the current location of the king.

This can be precomputed into a lookup table:

	evasion_bb = evasions[king_shift][evasion_mask]

##### Engine: Check Source Squares (12 bits)

This used to be 64 bits but can be easily compressed to just 12 bits. At most
two pieces can give check simultaneously. Instead of storing the bitmask, we
store the shift (6 bits) of both pieces in 2 x 6 = 12 bits.

This field combined with the field above (check evasion squares) is the
indicator that the current side is in check. We need the lookups and bit
shifting only in the relatively rare case of a check, and even then we
only use relatively cheap operations to restore the full information.

We have find out whether it is cheaper to compute the bitboard on-the-fly or
precompute it into a lookup table with the 12-bit bitmask as the index.

##### Engine: Raw Material Balance (7 bits)

The maximum material advantage is 103 (2 rooks, 2 bishops, 2 knights, 9 queens).
That fits into 7 bits.

### Move

The structure has not changed.

* colour/turn (1 bit)
* piece-type (3 bits)
* from-square (3 bits)
* to-square (3 bits)
* en-passant flag (1 bit)
* capture piece-type (3 bits)
* promotion piece-type (3 bits)

17 bits so far, leaving 47 bits for other purposes.

The colour/turn flag is not strictly necessary because it is implied by the
current position. But we use the move as an (integer) index into lookup tables,
and they would become slightly slower, when an additional level of indirection
is used for the colour.

## Move Generation

### New API (`move/unmove`)

We currently have the luxury API `applyMove/unapplyMove` with an argument that
is either a move as a string in SAN or LAN format or a packed integer move.
These methods internally invoke `doMove/undoMove` which only work with packed
integer moves.

We add two additional methods that will be a lot faster:

```perl
my $undo = $pos->move($move);
# ... do something
$pos->unmove($undo, $move);
```

Both `$move` and `$undo` will be packed integers. The undo information returned
by the existing API is really an array. The optimisation is possible because
we can encode the entire state required to restore the position into 64 bits.

The engine will override these new methods. It will stuff the additional
information needed into the move and into the undo state. The position
bitfield has 14 spare bits, the move has 47 spare bits. This will give us room
for:

* reversible clock (22 bits)
* raw material balance (7 bits)
* capture piece mask (3 bits)

The entire body of the `move/unmove` methods in the core library should be
put together with macros. That makes it easy for the engine to override the
method without an additional invocation.

## Engine

### Commandline Arguments

The engine should accept command line arguments, especially a command file
that will be processed in strictly sequential order. Currently, if you just
paste commands into the terminal, it will execute them instantly.

It should also have arguments that will create ASCII art boards, do
all kinds of evaluations, dump bitboards and so on.

### Time Management

The new time management should be invoked, whenever the iteration depth
increases. This way, unstable searches can increase the allocated time,
whereas very stable searches can decrease it.

We also measure the move overhead. It can initially be set with an option,
but later be measured by simply look at how long the search took and compare
that with the time taken from our clock. As long as we detect a continuous
game, the move overhead is exactly the difference between the two values.

### Evaluation Experiments

#### Encourage Castling

Castling should receive a bonus. The PSTs should then probably be adapted
because they contain bonuses for the king on c8 or g8. These bonuses should
maybe only be applied, when the move is really a castling.

On the other hand, these squares are objectively good squares for the king
but only behind pawns, and maybe a bishop and a king. That would rather
suggest a dynamic evaluation of king safety.

#### Bishop Pair

We can give moves where a minor piece captures a bishop a bonus. This can
be precomputed.

#### Poisoned Pawn

The PSTs contain a penalty for the queen on b7 or g7. Part of it can be
removed from the PSTs and added to captures where the capturing piece is a
queen and the captured piece is a pawn. This penalty can be precomputed into
the lookup table.

#### Encourage Exchange of Pieces

We can slightly modify the SEE, when one side is roughly 200 or more centipawns
ahead. The SEE should then never return 0 but a slightly higher evaluation or
that bonus should be added by the search. As a result, the engine should
actively try to simplify the position. We can also try whether it is good to
increase the bonus proportionally to the static evaluation.

Maybe, the raw material count is a better indicator for this because a high
evaluation can also be a sign of a lot of tension that could vanish if the
position is simplified.
