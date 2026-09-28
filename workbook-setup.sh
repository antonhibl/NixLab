#!/usr/bin/env bash
set -u
d=/root/workbook-data
[ -d /root/corpus ] || bash /opt/nixlab/provision-corpus.sh /root/corpus
reset=
[ "${1:-}" = --reset ] && reset=1
if [ -z "$reset" ] && [ -e "$d/.provisioned" ] && [ -d "$d/debug" ]; then
    echo "workbook-data already set up (--reset to restore the exercise files)"
    exit 0
fi

debug_files() {
D="$d/debug"
mkdir -p "$D/c" "$D/py" "$D/go" "$D/elisp" "$D/lisp"

cat > "$D/c/avg.c" <<'C'
#include <stdio.h>

static int sum(const int *xs, int n) {
    int total = 0;
    for (int i = 0; i <= n; i++)
        total += xs[i];
    return total;
}

static double average(const int *xs, int n) {
    return sum(xs, n) / n;
}

int main(void) {
    int scores[] = { 90, 85, 77, 68, 96 };
    int n = sizeof scores / sizeof scores[0];
    printf("average: %.2f (expected 83.20)\n", average(scores, n));
    return 0;
}
C

cat > "$D/c/crash.c" <<'C'
#include <stdio.h>

struct employee {
    const char *name;
    struct employee *manager;
};

static const char *manager_name(const struct employee *e) {
    return e->manager->name;
}

int main(void) {
    struct employee ada = { "Ada", NULL };
    struct employee alan = { "Alan", &ada };
    struct employee grace = { "Grace", &ada };
    struct employee *team[] = { &alan, &grace, &ada };
    for (int i = 0; i < 3; i++)
        printf("%s reports to %s\n", team[i]->name, manager_name(team[i]));
    return 0;
}
C

cat > "$D/py/tally.py" <<'PY'
import json


def load(path):
    with open(path) as f:
        return json.load(f)


def tally(tickets, counts={}):
    for t in tickets:
        counts[t["status"]] = counts.get(t["status"], 0) + 1
    return counts


def main():
    tickets = load("/root/corpus/tickets.json")
    first = tally(tickets[:100])
    second = tally(tickets[100:])
    print("first half :", first)
    print("second half:", second)
    print("total      :", sum(first.values()) + sum(second.values()), "expected", len(tickets))


if __name__ == "__main__":
    main()
PY

cat > "$D/py/report.py" <<'PY'
import csv


def by_dept(path):
    rows = {}
    with open(path) as f:
        for row in csv.DictReader(f):
            rows.setdefault(row["dept"], []).append(int(row["salary"]))
    return rows


def main():
    depts = by_dept("/root/corpus/employees.csv")
    for name in ["eng", "sales", "marketing", "ops"]:
        salaries = depts[name]
        print(f"{name:10} {sum(salaries) / len(salaries):10.2f}")


if __name__ == "__main__":
    main()
PY

cat > "$D/go/go.mod" <<'GO'
module topwords

go 1.22
GO

cat > "$D/go/main.go" <<'GO'
package main

import (
	"fmt"
	"os"
	"sort"
	"strings"
	"unicode"
)

type count struct {
	word string
	n    int
}

func words(text string) []string {
	return strings.FieldsFunc(strings.ToLower(text), func(r rune) bool {
		return !unicode.IsLetter(r)
	})
}

func topN(ws []string, n int) []count {
	tally := map[string]int{}
	for _, w := range ws {
		tally[w]++
	}
	var out []count
	for w, c := range tally {
		out = append(out, count{w, c})
	}
	sort.Slice(out, func(i, j int) bool { return out[i].n < out[j].n })
	return out[:n]
}

func main() {
	data, err := os.ReadFile("/root/corpus/sherlock.txt")
	if err != nil {
		panic(err)
	}
	for _, c := range topN(words(string(data)), 5) {
		fmt.Printf("%6d %s\n", c.n, c.word)
	}
}
GO

cat > "$D/elisp/salary.el" <<'EL'
;;; salary.el --- a buggy function to debug  -*- lexical-binding: t; -*-

(defun nixlab-average-salary (dept)
  "Average salary of DEPT in employees.csv."
  (let ((total 0)
        (count 0))
    (with-temp-buffer
      (insert-file-contents "/root/corpus/employees.csv")
      (forward-line 1)
      (while (not (eobp))
        (let ((fields (split-string
                       (buffer-substring (line-beginning-position)
                                         (line-end-position))
                       ",")))
          (when (string= (nth 3 fields) dept)
            (setq total (+ total (nth 4 fields)))
            (setq count (1+ count))))
        (forward-line 1)))
    (/ total count)))
EL

cat > "$D/lisp/means.lisp" <<'LISP'
(declaim (optimize (debug 3)))

(defun mean (xs)
  (/ (reduce #'+ xs) (length xs)))

(defun dept-means (depts)
  (loop for (name . salaries) in depts
        collect (cons name (mean salaries))))

(defun fact (n)
  (if (= n 0)
      1
      (* n (fact (- n 1)))))
LISP
}

if [ -n "$reset" ] || [ ! -e "$d/.provisioned" ]; then
rm -rf "$d/messy"
mkdir -p "$d/messy" "$d/c" "$d/practice"

( cd "$d/messy"
  : > "annual report 2024.txt"
  : > "notes - draft.md"
  : > "IMG_0001.JPG"
  : > "IMG_0002.JPG"
  : > "  leading-space.txt"
  : > "weird;name&here.dat" )

cat > "$d/c/leaky.c" <<'C'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(void) {
    char *buf = malloc(8);          /* deliberately too small */
    strcpy(buf, "hello, world");    /* writes past the 8 bytes */
    printf("%s\n", buf);
    return 0;                       /* and never frees buf */
}
C

cat > "$d/c/offbyone.c" <<'C'
#include <stdio.h>
int main(void) {
    int a[5];
    for (int i = 0; i <= 5; i++)    /* <= writes a[5], one past the end */
        a[i] = i * i;
    printf("%d\n", a[2]);
    return 0;
}
C

cat > "$d/practice/motions.txt" <<'TXT'
MOTION DRILLS. Stay in normal mode (<N> in the mode line). No arrow keys.

Press j to come down here. Press k to go back up. Now press 5j.
You moved five lines at once. Counts work in front of almost every motion.

The quick brown fox jumps over the lazy dog, then naps in the warm sun.
  w jumps to the start of the next word, b jumps back, e to a word's end.
  0 goes to column zero, ^ to the first non-blank, $ to the end of the line.

fx jumps forward to the next "x" on this line: find the x in the word "box".
tx stops just before it. ; repeats the last f/t, and , repeats it backwards.

Paragraphs are separated by blank lines. } jumps to the next blank line,
{ jumps back to the previous one. Try it a few times from here.

This paragraph is a landing pad for } and {.
It has three lines so you can see where you land.
The cursor stops on the blank line after it.

gg jumps to the top of the buffer. G jumps to the bottom. 12G goes to line 12.
C-d scrolls half a page down, C-u half a page up. zz centres the cursor line.

Searching: type /TREASURE then RET. n finds the next hit, N the previous one.
Put the cursor on any word and press * to search for that exact word.

Brackets: put the cursor on this ( and press % to jump to its partner ).
Nested [ { ( ) } ] works too. % always finds the match.

After a big jump, C-o takes you back to where you were. Very handy.

...
...
...
TREASURE number one is here.
...
...
TREASURE number two is here.
...
The last line. G brought you here; now gg takes you home.
TXT

cat > "$d/practice/edit-me.txt" <<'TXT'
EDIT DRILLS. Fix each line in normal mode; the hint says which keys to use.

1.  the the quick brown fox                     remove the doubled "the"   (dw)
2.  the slow train leaves at noon                  change slow to fast       (cw)
3.  say "goodbye" to the old habits           make it say "hello"        (ci")
4.  greet(name, age, city, planet)               make it greet(user)        (ci()
5.  keep this part DELETE EVERYTHING FROM HERE      delete from DELETE on (D)
6.  shout                                           uppercase the word       (gUiw)
7.  count = 41                                      make it 42               (r2)
8.  second
9.  first                                           swap lines 8 and 9       (ddp)
10. one half
11. and the other half                              join 10 and 11 into one  (J)
12. duplicate me                                    three copies below       (yy3p)
13. apples
14. pears
15. plums
16. figs                                            turn 13-16 into "- apples" etc. with a macro (qa ... q, 3@a)
TXT

cat > "$d/practice/parens.lisp" <<'LISP'
;; STRUCTURAL EDITING DRILLS (paredit). Put the cursor where the arrow says.

;; 1. slurp: cursor inside the list, SPC k s        (+ 1 2) 3        =>  (+ 1 2 3)
(+ 1 2) 3

;; 2. barf: cursor inside the list, SPC k b         (list 1 2 3 4)   =>  (list 1 2 3) 4
(list 1 2 3 4)

;; 3. backward slurp: cursor inside, SPC k S        a (b c)          =>  (a b c)
a (b c)

;; 4. wrap: cursor on x, SPC k w, then type print   x                =>  (print x)
x

;; 5. raise: cursor on (compute), SPC k r           (when t (compute)) => (compute)
(when t (compute))

;; 6. splice: cursor on progn, SPC k W        (progn (a) (b))  =>  (a) (b)
(progn (a) (b))

;; 7. split then join: cursor after 2, SPC k J; then between the lists, SPC k j
(1 2 3 4)
LISP

cat > "$d/practice/hello.lisp" <<'LISP'
(defun greet (name)
  (format nil "Hello, ~a!" name))

(defun average (numbers)
  (/ (reduce #'+ numbers) (length numbers)))

(defun broken ()
  (car 5))
LISP

cat > "$d/practice/playground.org" <<'ORG'
#+TITLE: Org playground

* Groceries
- milk
- bread

* Notes
Write anything here.
ORG

fi

if [ -n "$reset" ] || [ ! -d "$d/debug" ]; then
    debug_files
fi

touch "$d/.provisioned"
echo "corpus:"; ls -1 /root/corpus
echo; echo "workbook-data:"; find "$d" -type f ! -name .provisioned | sort
echo; echo "Setup complete."
