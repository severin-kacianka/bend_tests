#!/usr/bin/env python3
"""Find a cell's (row, col) in a captured snake.bend frame.

Usage: parse_frame.py CHAR < frame.txt
Prints "row col" (0-based, within the 20x20 grid) for the first grid row
containing CHAR, or nothing if not found.
"""
import sys


def main():
    ch = sys.argv[1]
    text = sys.stdin.read()
    grid_lines = [
        line for line in text.split("\n")
        if len(line) == 20 and all(c in ".@o*" for c in line)
    ][:20]
    for row, line in enumerate(grid_lines):
        col = line.find(ch)
        if col != -1:
            print(row, col)
            return


if __name__ == "__main__":
    main()
