import Base
import ./snake_buggy.bend as Game
import ./LAWS_buggy.bend as Laws

def Laws.Dir.is_opposite.sym(a, b):
  match a b:
    case Game.Up{} Game.Up{}:
      {==}
    case Game.Up{} Game.Down{}:
      {==}
    case Game.Up{} Game.Left{}:
      {==}
    case Game.Up{} Game.Right{}:
      {==}
    case Game.Down{} Game.Up{}:
      {==}
    case Game.Down{} Game.Down{}:
      {==}
    case Game.Down{} Game.Left{}:
      {==}
    case Game.Down{} Game.Right{}:
      {==}
    case Game.Left{} Game.Up{}:
      {==}
    case Game.Left{} Game.Down{}:
      {==}
    case Game.Left{} Game.Left{}:
      {==}
    case Game.Left{} Game.Right{}:
      {==}
    case Game.Right{} Game.Up{}:
      {==}
    case Game.Right{} Game.Down{}:
      {==}
    case Game.Right{} Game.Left{}:
      {==}
    case Game.Right{} Game.Right{}:
      {==}

def Laws.Dir.is_opposite.irrefl(d):
  match d:
    case Game.Up{}:
      {==}
    case Game.Down{}:
      {==}
    case Game.Left{}:
      {==}
    case Game.Right{}:
      {==}

def Laws.Snake.turn.no_reversal(pending, dir):
  match pending dir:
    case Game.Up{} Game.Up{}:
      {==}
    case Game.Up{} Game.Down{}:
      {==}
    case Game.Up{} Game.Left{}:
      {==}
    case Game.Up{} Game.Right{}:
      {==}
    case Game.Down{} Game.Up{}:
      {==}
    case Game.Down{} Game.Down{}:
      {==}
    case Game.Down{} Game.Left{}:
      {==}
    case Game.Down{} Game.Right{}:
      {==}
    case Game.Left{} Game.Up{}:
      {==}
    case Game.Left{} Game.Down{}:
      {==}
    case Game.Left{} Game.Left{}:
      {==}
    case Game.Left{} Game.Right{}:
      {==}
    case Game.Right{} Game.Up{}:
      {==}
    case Game.Right{} Game.Down{}:
      {==}
    case Game.Right{} Game.Left{}:
      {==}
    case Game.Right{} Game.Right{}:
      {==}

# ---- Coord.eq.refl, via U32.is_eq reflexivity (not provided by Base) ----

def Word.cmp.fin.same(hb: Bool) -> {Word.cmp.fin(hb, hb, EQ{}) == EQ{} : Cmp}:
  match hb:
    case False{}:
      {==}
    case True{}:
      {==}

def Word.cmp.refl(n: Nat, w: Word(n)) -> {Word.cmp(n, w, w) == EQ{} : Cmp}:
  match n:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+p:
      match w:
        case WCon{hb, wt}:
          %Equal.sym(Cmp, Word.cmp(p, wt, wt), EQ{}, Word.cmp.refl(p, wt)) :
            {Word.cmp.fin(hb, hb, _) == EQ{} : Cmp}
          Word.cmp.fin.same(hb)

def U32.cmp.refl(a: U32) -> {U32.cmp(a, a) == EQ{} : Cmp}:
  match a:
    case U32{w}:
      Word.cmp.refl(32n, w)

def U32.is_eq.refl(a: U32) -> {U32.is_eq(a, a) == True{} : Bool}:
  %Equal.sym(Cmp, U32.cmp(a, a), EQ{}, U32.cmp.refl(a)) :
    {Cmp.is_eq(_) == True{} : Bool}
  {==}

def Laws.Coord.eq.refl(c):
  match c:
    case Game.Coord{x, y}:
      %Equal.sym(Bool, U32.is_eq(x, x), True{}, U32.is_eq.refl(x)) :
        {Bool.and(_, U32.is_eq(y, y)) == True{} : Bool}
      %Equal.sym(Bool, U32.is_eq(y, y), True{}, U32.is_eq.refl(y)) :
        {Bool.and(True{}, _) == True{} : Bool}
      {==}

# ---- eating grows, moving preserves length ----

# grown_body is a plain cons, so List.length's own definition unfolds
# both sides to the same term: no case split needed at all.
def Laws.Snake.grown_body.length(newHead, body):
  {==}

# moved_body re-derives List.take's own recursion, so this needs a real
# induction lemma: taking exactly |t| elements from h<>t always yields a
# list of length |t| (there's always one more element, h, to spare).
def List.cons_take_own_length(-h: Game.Coord, t: List<&2, Game.Coord>) ->
  {List.length(&2, Game.Coord, List.take(&2, Game.Coord, h <> t, List.length(&2, Game.Coord, t)))
    == List.length(&2, Game.Coord, t) : Nat}:
  match t:
    case Nil{}:
      {==}
    case h2 <> t2:
      %Equal.sym(Nat,
        List.length(&2, Game.Coord, List.take(&2, Game.Coord, h2 <> t2, List.length(&2, Game.Coord, t2))),
        List.length(&2, Game.Coord, t2),
        List.cons_take_own_length(h2, t2)) :
        {(1n + _ : Nat) == (1n + List.length(&2, Game.Coord, t2) : Nat) : Nat}
      {==}

def Laws.Snake.moved_body.length(newHead, body):
  List.cons_take_own_length(newHead, body)
