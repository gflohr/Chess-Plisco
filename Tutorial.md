# Chess::Position::Tutorial - An Introductory Tutorial to Chess Programming in Perl With `Chess::Position`

Let's start by explaining the fundamental data structures.

## Data Structures

### Bitboards

A real chess board looks roughly likes this:

```
     a   b   c   d   e   f   g   h
   +---+---+---+---+---+---+---+---+
 8 | r | n | b | q | k | b | n | r |
   +---+---+---+---+---+---+---+---+
 7 | p | p | p | p | p | p | p | p |
   +---+---+---+---+---+---+---+---+
 6 |   | . |   | . |   | . |   | . |
   +---+---+---+---+---+---+---+---+
 5 | . |   | . |   | . |   | . |   |
   +---+---+---+---+---+---+---+---+
 4 |   | . |   | . |   | . |   | . |
   +---+---+---+---+---+---+---+---+
 3 | . |   | . |   | . |   | . |   |
   +---+---+---+---+---+---+---+---+
 2 | P | P | P | P | P | P | P | P |
   +---+---+---+---+---+---+---+---+
 1 | R | N | B | Q | K | B | N | R |
   +---+---+---+---+---+---+---+---+
     a   b   c   d   e   f   g   h
```

The board has eight columns, called "files", named "a" to "h", and eight rows,
called "ranks", named "1" to "8".  The initial position of the white king "K"
is "e1", the intersection of the "e" file and the "1"st rank. Likewise, the
white queen "Q" is on "d1", and the black king "k" and black queen "q" are
initially located on "e8" and "d8" respectively.

It is, of course, possible to use an intuitive board representation like an
array of arrays or even a hash, and there are chess libraries that do exactly
that. The main drawback of this approach is performance because all operations
on the board imply expensive lookups and dereferencings.

A more efficient representation takes advantage of the fact that a chess board
has exactly 64 squares.  Nowadays, most computers use integers of size 64.  And
so you can represent a chess board, more exactly one single aspect of a chess
board, as 64-bit integer, each bit representing exactly one square of the board.

But with just one bit of information per square, you cannot represent a chess
position, because there are 12 different pieces: Pawns, knights, bishops, rooks,
queens, and kings in both black and white.  The solution is to use multiple
such bitboards, and combine them.

A `Chess::Position` instance is an array of arrays of integers, and the first
few are:

- `w_pieces` - one bitboard for the white pieces
- `b_pieces` - one bitboard for the black pieces
- `kings` - one bitboard for the kings (of both colors)
- `rooks` - one bitboard for the rooks (of both colors)
- `bishops` - one bitboard for the bishops (of both colors)
- `knights` - one bitboard for the knights (of both colors)
- `pawns` - one bitboard for the pawns (of both colors)

Why is there no distinction between black and white pieces of a certain kind,
for example black knights and white knights?  The answer is performance and
compactness.  To get a bitboard with one bit set for each black knight, you
simple do the bitwise AND of the two bitboards:

```perl
$black_knights = $b_pieces & $knights
```

In other words: For each black knight, there must be one bit set in the bitboard
of black pieces AND in the knight bitboard.

Example: How to get a bitboard of white's regular (bishops, knights, rooks, and
queens):

```perl
$w_pieces & ($knights | $bishops | $rooks)
```

Now you probably ask yourself, why there is no bitboard for the queens.

The main purpose of bitboards is to generate a list of possible resp. legal
moves in a certain position, and to find out which squares the pieces control
or attack.  In that respect, a queen is simply a combination of a bishop
and a rook.

When the moves are getting generated, it would be an inefficient waste of time
to generate the queen moves in a separate step.  Look at it:

1. generate (diagonal) bishop moves
2. generate (horizontal and vertical) rook moves
3. generate diagonal queen moves
4. generate horizontal and vertical queen moves

This can be done faster

1. generate diagonal bishop and queen moves
2. generate horizontal and vertical rook and queen moves

To find out, whether the move is performaced by a queen or a bishop, or rook,
you just have to look at the starting square of the move.  If it is occupied
by a queen, it is a queen move, otherwise a bishop or rook move.

The drawback of this is that it is a little more complicated to get a bitboard
of the bishops, rooks, and queens:

```perl
$white_queens = $w_pieces & $bishops & $rooks
$white_rooks = $w_pieces & ($rooks & ~$bishops)
$white_bishops = $w_pieces & ($bishops & ~$rooks)
```

But these bitwise operations are very fast and cheap, and in fact, you rarely
have to find out whether a square is really occupied by a queen or a rook.

### Other Board Representations

#### Forsyth-Edwards Notation FEN

The Forsyth-Edwards Notation of a chess position is mostly used for data
exchange between chess software.  See for example the [Wikipedia article
on FEN](https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation) for
details.

The constructor `newFromFEN()` of `Chess::Position` can be used to initialize
a chess position from a FEN string.

#### Extended Position Description EPD

A similar notation to FEN is the [Extended Position
Description](https://en.wikipedia.org/wiki/Extended_Position_Description).
You can think of it as FEN with meta data.

### Coordinates and Squares

The chess board is actually a Cartesian coordinate system.  There are
multiple ways, how a particular point in that coordinate system can be
specified.  In `Chess-Position` we use the terms "coordinates", "squares",
and "shifts", and you can convert between all of them with dedicated class
methods:

* `my $square = Chess::Position->coordinatesToSquare($file, $rank)`
* `my $shift = Chess::Position->coordinatesToShift($file, $rank)`
* `my $shift = Chess::Position->squareToShift($square)`
* `my ($file, $rank) = Chess::Position->squareToCoordinates($square)`
* `my $square = Chess::Position->shiftToSquare($shift)`
* `my ($file, $rank) = Chess::Position->shiftToCoordinates($shift)`

Additionally, we also have "square masks" (see below).

#### Coordinates

When we talk of coordinates, we mean a pair of a file and a rank, but they
are always 0-based indexes.  So the files "a" to "h" are indexed as 0 ... 7,
and the ranks "1" to "8" are indexed as 0 ... 7.

#### Squares

Squares are conventional coordinates like "e4" or "c7".  They are only used
for presentational purposes.

#### Shifts

A bitboard has 64 bits, and each bit stands for a particular square of the
chess board:

```
   a  b  c  d  e  f  g  h
8 63 62 61 60 59 58 57 56 8
7 55 54 53 52 51 50 49 48 7
6 47 46 45 44 43 42 41 40 6
5 39 38 37 36 35 34 33 32 5
4 31 30 29 28 27 26 25 24 4
3 23 22 21 20 19 18 17 16 3
2 15 14 13 12 11 10  9  8 2
1  7  6  5  4  3  2  1  0 1
   a  b  c  d  e  f  g  h
```

So the square "e4" is represented by the bit with the index 27 of a bitboard
(actually the 28th bit if you count from 1).  So, a better term may actually
be "index" or "bit number".

#### Shift Masks

How would you find out whether the square "e4" is occupied by a white piece?
You create a bitboard (64-bit integer) where only the 27th bit is set and AND
that with the bitboard of the white pieces.  And you create a bitboard
where only the 27th bit is set with a shift operation:

```perl
$e4_square = (1 << 27) | $w_pieces
```

You "shift" the one 27 places to the left.  And this is why the indexes or
bit numbers are called "shifts" here.  And a shift mask is a bitboard with
exactly one bit set.

### `Chess::Position` Instances

Unlike most Perl objects, instances of `Chess::Position` are blessed array
references.  This design decision was taken because accessing accessing
array elements is faster than accessing hash elements.  But there is no
need to remember the exact ordering of the array.  You can either use
dedicated macros that operate on directly on `Chess::Position` indexes
or use constants for the indexes:

```
use Chess::Position (:all);
use Chess::Position::Macro;

$pos = Chess::Position->new;

# Equivalent!
$w_pieces = $pos[CP_POS_W_PIECES];
$pos[CP_POS_W_PIECES] = $_pieces;
$w_pieces = cp_pos_w_pieces $pos;
cp_pos_w_pieces $pos = $w_pieces;
```

### Pieces

The chess pieces are specified by an enumeration:

* `CP_NO_PIECE` 0
* `CP_PAWN` 1
* `CP_KNIGHT` 2
* `CP_BISHOP` 3
* `CP_ROOK` 4
* `CP_QUEEN` 5
* `CP_KING` 6

The default values are defined by these constants in `Chess::Position`:

* `CP_PAWN_VALUE` 100
* `CP_KNIGHT_VALUE` 300
* `CP_BISHOP_VALUE` 300
* `CP_ROOK_VALUE` 500
* `CP_QUEEN_VALUE` 900

These constants can be overridden in derived classes.  This is not
recommended for the constants specifiying the pieces (see above), as the data
values may not fit into the other structures.

### Moves

A move in `Chess::Position` is simply an integer.  There is also a convenience
class `Chess::Position::Move` which is constructed from a reference to an
integer but this class is not used internally for performance reasons.  The
individual bits of a move are:

* 21-.. (20-..): raw material balance (viewed from the side to move)
* 20-22 (19-21): piece that gets removed (resp. victim) if any
* 17-19 (16-18): piece that moves (resp. attacker)
*    16 (15): en passant flag
* 13-15 (12-14): promotion piece
*  7-12 (6-11): from shift (0-63)
*  1- 6 (0- 5): to shift (0-63)

*The numbers in parentheses are the 0-based bit numbers.*

Only bits 1 to 15 are really needed to characterize a move, and the bits 13 to
15 are only needed for pawn promotions.  The other bits can be derived from
the position that the move is applied to, and there are not always present:

The en passant flag is set, when a pawn hits (moves diagonally) but the target
square is empty.

The piece that moves, the attacker is the piece that stands on the starting
square.

The piece that gets removed, the victim, is the piece that stands on the target
square, if any.

The raw material balance is only added to a move, when moves are meant to
be sorted.

You do not have to remember the exact structure of a move but use macros
resp. inline functions for accessing individual properties:

* `cp_move_to($move)`: the starting square as a shift
* `cp_move_from($move)`: the destination square as a shift
* `cp_move_promotion($move)`: the promotion piece
* `cp_move_attacker($move)`: the attacking piece
* `cp_move_victim($move)`: the captured piece if any
* `cp_move_material($move)`: the raw material balance

None of these macros can be used as l-values (on the left-hand side of an
assignment)!  For this, use other macros:

* `cp_move_set_to($move, $to)`: the starting square as a shift
* `cp_move_set_from($move, $from)`: the destination square as a shift
* `cp_move_set_promotion($move, $piece)`: the promotion piece
* `cp_move_set_attacker($move, $piece)`: the attacking piece
* `cp_move_set_victim($move, $piece)`: the captured piece if any
* `cp_move_set_material($move, $mat)`: the raw material balance

In fact, the semantics of the raw material balance are not well-defined.
Actually, it is just whatever is stored in the upper bits of the move.  So,
you can stuff in there whatever you want to use for sorting or comparing
moves.