import Base

# ---- Geometry ----

type Dir is Data:
  Up{}
  Down{}
  Left{}
  Right{}

type Coord is Data:
  Coord{x: U32, y: U32}

def Coord.eq(a: Coord, b: Coord) -> Bool:
  match a b:
    case Coord{ax, ay} Coord{bx, by}:
      Bool.and(U32.is_eq(ax, bx), U32.is_eq(ay, by))

def Dir.is_opposite(a: Dir, b: Dir) -> Bool:
  match a b:
    case Up{} Down{}:
      True{}
    case Down{} Up{}:
      True{}
    case Left{} Right{}:
      True{}
    case Right{} Left{}:
      True{}
    case _ _:
      False{}

def Dir.step(d: Dir, c: Coord) -> Coord:
  match d c:
    case Up{} Coord{x, y}:
      Coord{x, U32.mod((y + 19 : U32), 20)}
    case Down{} Coord{x, y}:
      Coord{x, U32.mod((y + 1 : U32), 20)}
    case Left{} Coord{x, y}:
      Coord{U32.mod((x + 19 : U32), 20), y}
    case Right{} Coord{x, y}:
      Coord{U32.mod((x + 1 : U32), 20), y}

def Maybe.eq_coord(m: Maybe<&2, Coord>, c: Coord) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{h}:
      Coord.eq(h, c)

# ---- Game state ----

type GameState is Data:
  Playing{body: List<&2, Coord>, dir: Dir, pending: Dir, food: Coord, score: U32}

type Step is Data:
  Alive{state: GameState}
  Dead{score: U32}

def Term.esc() -> String:
  String.from_list([Char.from_u32(27)])

def Term.nl() -> String:
  String.from_list([Char.from_u32(13), Char.from_u32(10)])

# ---- Rendering ----

def Grid.cell_char.pick3(isFood: Bool) -> String:
  match isFood:
    case True{}:
      "*"
    case False{}:
      "."

def Grid.cell_char.pick2(isBody: Bool, isFood: Bool) -> String:
  match isBody:
    case True{}:
      "o"
    case False{}:
      Grid.cell_char.pick3(isFood)

def Grid.cell_char.pick1(isHead: Bool, isBody: Bool, isFood: Bool) -> String:
  match isHead:
    case True{}:
      "@"
    case False{}:
      Grid.cell_char.pick2(isBody, isFood)

def Grid.cell_char(x: U32, y: U32, +body: List<&2, Coord>, +food: Coord) -> String:
  +here = {Coord{x, y} : Coord}
  isHead = Maybe.eq_coord(List.head(&2, Coord, body), here)
  isBody = List.contains(~Coord, ~Coord.eq, body, here)
  isFood = Coord.eq(here, food)
  Grid.cell_char.pick1(isHead, isBody, isFood)

def Grid.render_row(fuel: Nat, +y: U32, +x: U32, +body: List<&2, Coord>, +food: Coord) -> String:
  match fuel:
    case 0n:
      ""
    case 1n+f:
      Grid.cell_char(x, y, body, food) ++ Grid.render_row(f, y, (x + 1 : U32), body, food)

def Grid.render_rows(fuel: Nat, +y: U32, +body: List<&2, Coord>, +food: Coord) -> String:
  match fuel:
    case 0n:
      ""
    case 1n+f:
      Grid.render_row(20n, y, 0, body, food) ++ Term.nl() ++ Grid.render_rows(f, (y + 1 : U32), body, food)

def Grid.render(state: GameState) -> String:
  match state:
    case Playing{body, dir, pending, food, score}:
      Grid.render_rows(20n, 0, body, food) ++ "Score: " ++ U32.show(score) ++ Term.nl()

# ---- Terminal control ----

def Term.clear_home() -> String:
  Term.esc() ++ "[2J" ++ Term.esc() ++ "[H"

def Term.raw_on() -> IO(Unit):
  IO.bind(U32 & (String & String), Unit,
    IO.try(U32 & (String & String),
      Process.run("stty", ["-F", "/dev/tty", "raw", "-echo", "min", "0", "time", "2"], "", 4096, 2000)),
    res => IO.pure(Unit, Unit{}))

def Term.raw_off() -> IO(Unit):
  IO.bind(U32 & (String & String), Unit,
    IO.try(U32 & (String & String),
      Process.run("stty", ["-F", "/dev/tty", "sane"], "", 4096, 2000)),
    res => IO.pure(Unit, Unit{}))

def Term.open() -> IO(File):
  IO.try(File, File.open("/dev/tty", "r"))

# ---- Key reading ----
#
# Term.raw_on sets termios VMIN=0 VTIME=2: a read on /dev/tty always returns
# within ~200ms, with 0 bytes if no key arrived. This makes File.read_bytes
# safe to call directly and doubles as the game's own tick pacing -- no
# separate sleep/timer needed. (Two other approaches were tried and do NOT
# work on this Bend runtime (2.0.34): a plain File.read_bytes with no VTIME
# blocks indefinitely and stalls the *entire* event loop while outstanding,
# including unrelated Chan/IO.sleep-driven tasks, even under IO.within;
# and shelling out via Process.run to a subprocess reading /dev/tty gets the
# subprocess SIGTTIN-stopped forever, because Process.run's POSIX_SPAWN_SETSIGDEF
# flag resets the child's signal dispositions to default before exec.)

def Reader.read_byte.first(file2: File, bytes: List<&2, U32>) -> IO(File & U32):
  match bytes:
    case Nil{}:
      IO.pure(File & U32, (file2, 0))
    case h <> t:
      IO.pure(File & U32, (file2, h))

def Reader.read_byte.after(pair: File & Result<&1, &1, U32 & String, List<&2, U32>>) -> IO(File & U32):
  (file2, r) = pair
  IO.bind(List<&2, U32>, File & U32, IO.pass(List<&2, U32>, r),
    bytes => Reader.read_byte.first(file2, bytes))

def Reader.read_byte(file: File) -> IO(File & U32):
  IO.bind(File & Result<&1, &1, U32 & String, List<&2, U32>>, File & U32,
    File.read_bytes(file, 1),
    pair => Reader.read_byte.after(pair))

def Reader.decode_plain2(+b: U32) -> U32:
  isCtrlC = U32.is_eq(b, 3)
  Bool.pick(U32, isCtrlC, 5, 0)

def Reader.decode_plain(+b: U32) -> U32:
  isQ = U32.is_eq(b, 113)
  Bool.pick(U32, isQ, 5, Reader.decode_plain2(b))

def Reader.decode4(+b3: U32) -> U32:
  isLeft = U32.is_eq(b3, 68)
  Bool.pick(U32, isLeft, 4, 0)

def Reader.decode3(+b3: U32) -> U32:
  isRight = U32.is_eq(b3, 67)
  Bool.pick(U32, isRight, 3, Reader.decode4(b3))

def Reader.decode2(+b3: U32) -> U32:
  isDown = U32.is_eq(b3, 66)
  Bool.pick(U32, isDown, 2, Reader.decode3(b3))

def Reader.decode_arrow(+b3: U32) -> U32:
  isUp = U32.is_eq(b3, 65)
  Bool.pick(U32, isUp, 1, Reader.decode2(b3))

def Reader.next_key.esc3(pair2: File & U32) -> IO(File & U32):
  (file4, b3) = pair2
  IO.pure(File & U32, (file4, Reader.decode_arrow(b3)))

def Reader.next_key.esc2(pair: File & U32) -> IO(File & U32):
  (file3, b2) = pair
  IO.bind(File & U32, File & U32, Reader.read_byte(file3), pair2 => Reader.next_key.esc3(pair2))

def Reader.next_key.esc(file2: File) -> IO(File & U32):
  IO.bind(File & U32, File & U32, Reader.read_byte(file2), pair => Reader.next_key.esc2(pair))

def Reader.next_key.branch(isEsc: Bool, file2: File, b: U32) -> IO(File & U32):
  match isEsc:
    case False{}:
      IO.pure(File & U32, (file2, Reader.decode_plain(b)))
    case True{}:
      Reader.next_key.esc(file2)

def Reader.next_key.got(pair: File & U32) -> IO(File & U32):
  (file2, +b) = pair
  Reader.next_key.branch(U32.is_eq(b, 27), file2, b)

def Reader.next_key(file: File) -> IO(File & U32):
  IO.bind(File & U32, File & U32, Reader.read_byte(file), pair => Reader.next_key.got(pair))

# ---- Game logic ----

def Snake.head_of.pick(h: Maybe<&2, Coord>) -> Coord:
  match h:
    case None{}:
      Coord{0, 0}
    case Some{c}:
      c

def Snake.head_of(body: List<&2, Coord>) -> Coord:
  Snake.head_of.pick(List.head(&2, Coord, body))

def Snake.turn.pick(bad: Bool, pending: Dir, dir: Dir) -> Dir:
  match bad:
    case True{}:
      dir
    case False{}:
      pending

def Snake.turn(+pending: Dir, +dir: Dir) -> Dir:
  Snake.turn.pick(Dir.is_opposite(pending, dir), pending, dir)

def Snake.on_key.dir4(code: U32, +body: List<&2, Coord>, +dir: Dir, pending: Dir, +food: Coord, +score: U32) -> GameState:
  isLeft = U32.is_eq(code, 4)
  Bool.pick(GameState, isLeft, Playing{body, dir, Snake.turn(Left{}, dir), food, score},
    Playing{body, dir, pending, food, score})

def Snake.on_key.dir3(+code: U32, +body: List<&2, Coord>, +dir: Dir, pending: Dir, +food: Coord, +score: U32) -> GameState:
  isRight = U32.is_eq(code, 3)
  Bool.pick(GameState, isRight, Playing{body, dir, Snake.turn(Right{}, dir), food, score},
    Snake.on_key.dir4(code, body, dir, pending, food, score))

def Snake.on_key.dir2(+code: U32, +body: List<&2, Coord>, +dir: Dir, pending: Dir, +food: Coord, +score: U32) -> GameState:
  isDown = U32.is_eq(code, 2)
  Bool.pick(GameState, isDown, Playing{body, dir, Snake.turn(Down{}, dir), food, score},
    Snake.on_key.dir3(code, body, dir, pending, food, score))

def Snake.on_key.dir(+code: U32, +body: List<&2, Coord>, +dir: Dir, pending: Dir, +food: Coord, +score: U32) -> GameState:
  isUp = U32.is_eq(code, 1)
  Bool.pick(GameState, isUp, Playing{body, dir, Snake.turn(Up{}, dir), food, score},
    Snake.on_key.dir2(code, body, dir, pending, food, score))

def Snake.on_key(code: U32, state: GameState) -> GameState:
  match state:
    case Playing{body, dir, pending, food, score}:
      Snake.on_key.dir(code, body, dir, pending, food, score)

def Snake.spawn_food.draw() -> IO(Coord):
  IO.bind(U32, Coord, IO.try(U32, IO.random_u32()), rx =>
    IO.bind(U32, Coord, IO.try(U32, IO.random_u32()), ry =>
      IO.pure(Coord, Coord{U32.mod(rx, 20), U32.mod(ry, 20)})))

def Snake.spawn_food(fuel: Nat, +body: List<&2, Coord>) -> IO(Coord):
  match fuel:
    case 0n:
      Snake.spawn_food.draw()
    case 1n+f:
      IO.bind(Coord, Coord, Snake.spawn_food.draw(), +c =>
        Bool.pick(IO(Coord), List.contains(~Coord, ~Coord.eq, body, c),
          Snake.spawn_food(f, body), IO.pure(Coord, c)))

# BUG (deliberate): eating should prepend the new head, growing the body
# by one segment. This just returns the body unchanged -- the snake's
# score climbs but it never gets any longer. Violates LAWS.bend's
# Snake.grown_body.length.
def Snake.grown_body(newHead: Coord, body: List<&2, Coord>) -> List<&2, Coord>:
  body

def Snake.moved_body(newHead: Coord, +body: List<&2, Coord>) -> List<&2, Coord>:
  List.take(&2, Coord, newHead <> body, List.length(&2, Coord, body))

def Snake.advance.eaten(ate: Bool, +newHead: Coord, +dir: Dir, +body: List<&2, Coord>, +food: Coord, +score: U32) -> IO(Step):
  match ate:
    case False{}:
      IO.pure(Step, Alive{Playing{Snake.moved_body(newHead, body), dir, dir, food, score}})
    case True{}:
      +grown = Snake.grown_body(newHead, body)
      IO.bind(Coord, Step, Snake.spawn_food(8n, grown), newFood =>
        IO.pure(Step, Alive{Playing{grown, dir, dir, newFood, (score + 1 : U32)}}))

def Snake.advance.crashed(crashed: Bool, +newHead: Coord, +dir: Dir, +body: List<&2, Coord>, +food: Coord, +score: U32) -> IO(Step):
  match crashed:
    case True{}:
      IO.pure(Step, Dead{score})
    case False{}:
      Snake.advance.eaten(Coord.eq(newHead, food), newHead, dir, body, food, score)

def Snake.advance(state: GameState) -> IO(Step):
  match state:
    case Playing{+body, dir, +pending, food, score}:
      +newHead = Dir.step(pending, Snake.head_of(body))
      Snake.advance.crashed(List.contains(~Coord, ~Coord.eq, body, newHead), newHead, pending, body, food, score)

# ---- Main loop ----

type Next is Data:
  Continue{state: GameState}
  Stop{}

def Next.pick(-A: Type, n: Next, onStop: A, onContinue: GameState -> A) -> A:
  match n:
    case Stop{}:
      onStop
    case Continue{state}:
      onContinue(state)

def GameLoop.on_tick(step: Step) -> IO(Next):
  match step:
    case Dead{score}:
      IO.bind(Unit, Next, Term.raw_off(), u1 =>
        IO.bind(Unit, Next,
          IO.print("Game over! Score: " ++ U32.show(score) ++ " -- press any key to exit."),
          u2 => IO.pure(Next, Stop{})))
    case Alive{state}:
      IO.pure(Next, Continue{state})

def GameLoop.step(isQuit: Bool, code: U32, state: GameState) -> IO(Next):
  match isQuit:
    case True{}:
      IO.bind(Unit, Next, Term.raw_off(), u1 =>
        IO.bind(Unit, Next, IO.print("Bye!"), u2 => IO.pure(Next, Stop{})))
    case False{}:
      IO.bind(Step, Next, Snake.advance(Snake.on_key(code, state)), step => GameLoop.on_tick(step))

def GameLoop.on_key(+code: U32, state: GameState) -> IO(Next):
  GameLoop.step(U32.is_eq(code, 5), code, state)

def GameLoop.run(fuel: Nat, +state: GameState, pair: File & U32) -> IO(Unit):
  match fuel:
    case 0n:
      (file, code) = pair
      Term.raw_off()
    case 1n+f:
      (file, code) = pair
      IO.bind(Unit, Unit, IO.write(Term.clear_home() ++ Grid.render(state)), u =>
        IO.bind(Next, Unit, GameLoop.on_key(code, state), next =>
          Next.pick(IO(Unit), next, Term.raw_off(),
            s => IO.bind(File & U32, Unit, Reader.next_key(file), newPair => GameLoop.run(f, s, newPair)))))

def Main.initial_state() -> GameState:
  Playing{[Coord{10, 10}, Coord{9, 10}, Coord{8, 10}], Right{}, Right{}, Coord{15, 10}, 0}

def main() -> IO(Unit):
  IO.bind(Unit, Unit, Term.raw_on(), u1 =>
    IO.bind(File, Unit, Term.open(), tty =>
      IO.bind(File & U32, Unit, Reader.next_key(tty), pair =>
        GameLoop.run(4294967295n, Main.initial_state(), pair))))
