import Base
import ./snake_buggy.bend as Game

# The player-facing safety guarantee: turning can never point the snake
# straight back into the segment it just came from. If this law were
# false, tapping the opposite arrow key would be an instant, unavoidable
# suicide move.
law Snake.turn.no_reversal:
  for pending: Game.Dir
  for dir: Game.Dir
  {Game.Dir.is_opposite(Game.Snake.turn(pending, dir), dir) == False{} : Bool}

# "Opposite" should be a well-behaved relation: symmetric (order of the
# two directions doesn't matter) and irreflexive (no direction is its own
# opposite). Snake.turn.no_reversal doesn't strictly need these, but a
# broken is_opposite would make the game's steering silently inconsistent.
law Dir.is_opposite.sym:
  for a: Game.Dir
  for b: Game.Dir
  {Game.Dir.is_opposite(a, b) == Game.Dir.is_opposite(b, a) : Bool}

law Dir.is_opposite.irrefl:
  for d: Game.Dir
  {Game.Dir.is_opposite(d, d) == False{} : Bool}

# Every self-collision and food-eaten check hinges on Coord.eq correctly
# recognizing a coordinate as equal to itself.
law Coord.eq.refl:
  for c: Game.Coord
  {Game.Coord.eq(c, c) == True{} : Bool}

# Eating food must make the snake longer: Snake.grown_body is exactly the
# function Snake.advance.eaten calls when the head lands on the food, and
# it must always add one segment, never zero and never more than one.
law Snake.grown_body.length:
  for newHead: Game.Coord
  for body: List<&2, Game.Coord>
  {List.length(&2, Game.Coord, Game.Snake.grown_body(newHead, body))
    == (1n + List.length(&2, Game.Coord, body) : Nat) : Nat}

# The complement: moving without eating must NOT change the snake's
# length -- otherwise it could grow (or shrink) for free every tick.
law Snake.moved_body.length:
  for newHead: Game.Coord
  for body: List<&2, Game.Coord>
  {List.length(&2, Game.Coord, Game.Snake.moved_body(newHead, body))
    == List.length(&2, Game.Coord, body) : Nat}
