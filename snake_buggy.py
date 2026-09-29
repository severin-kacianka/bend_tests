#!/usr/bin/env python3
"""Nokia-style Snake, deliberately buggy -- see snake_buggy.bend.

Same bug as snake_buggy.bend's Snake.grown_body: eating should prepend
the new head (grow by one segment). Instead the body is left completely
untouched -- the snake doesn't even move on the tick it eats, let alone
grow. Score still climbs and food still respawns.
"""
import os
import random
import select
import sys
import termios
import tty

GRID = 20
TICK_TIMEOUT = 0.2
CLEAR_HOME = "\x1b[2J\x1b[H"

DIRS = {
    "up": (0, -1),
    "down": (0, 1),
    "left": (-1, 0),
    "right": (1, 0),
}
OPPOSITE = {
    "up": "down",
    "down": "up",
    "left": "right",
    "right": "left",
}


def step(direction, pos):
    dx, dy = DIRS[direction]
    x, y = pos
    return ((x + dx) % GRID, (y + dy) % GRID)


def turn(pending, current):
    return current if OPPOSITE[pending] == current else pending


def render(body, food, score):
    head = body[0]
    body_set = set(body)
    out = []
    for y in range(GRID):
        row = []
        for x in range(GRID):
            pos = (x, y)
            if pos == head:
                row.append("@")
            elif pos in body_set:
                row.append("o")
            elif pos == food:
                row.append("*")
            else:
                row.append(".")
        out.append("".join(row) + "\r\n")
    out.append(f"Score: {score}\r\n")
    return "".join(out)


def spawn_food(body):
    body_set = set(body)
    while True:
        candidate = (random.randrange(GRID), random.randrange(GRID))
        if candidate not in body_set:
            return candidate


def read_byte(fd, timeout=TICK_TIMEOUT):
    ready, _, _ = select.select([fd], [], [], timeout)
    if not ready:
        return None
    data = os.read(fd, 1)
    return data[0] if data else None


def next_key(fd):
    b = read_byte(fd)
    if b is None:
        return None
    if b == 27:
        b2 = read_byte(fd)
        b3 = read_byte(fd)
        return {65: "up", 66: "down", 67: "right", 68: "left"}.get(b3)
    if b == ord("q") or b == 3:
        return "quit"
    return None


def main():
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    tty.setraw(fd)
    final_message = None
    try:
        body = [(10, 10), (9, 10), (8, 10)]
        direction = "right"
        pending = "right"
        food = (15, 10)
        score = 0

        while True:
            os.write(1, (CLEAR_HOME + render(body, food, score)).encode())
            key = next_key(fd)
            if key == "quit":
                final_message = "Bye!"
                break
            if key in DIRS:
                pending = turn(key, direction)

            new_head = step(pending, body[0])
            if new_head in body:
                final_message = f"Game over! Score: {score} -- press any key to exit."
                break

            direction = pending
            if new_head == food:
                # BUG: should be `body = [new_head] + body` (grow by one).
                score += 1
                food = spawn_food(body)
            else:
                body = [new_head] + body[:-1]
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)

    if final_message:
        print(final_message)
    sys.exit(0)


if __name__ == "__main__":
    main()
