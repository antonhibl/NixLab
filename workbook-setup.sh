#!/usr/bin/env bash
set -u
d=/root/workbook-data
[ -d /root/corpus ] || bash /opt/nixlab/provision-corpus.sh /root/corpus
reset=
[ "${1:-}" = --reset ] && reset=1
datasets="$d/debug $d/shell /srv/lab/perms $d/procs $d/toolbox $d/git $d/archive $d/sql $d/net/mkroute.sh /opt/scenario/.provisioned /opt/binexp/.provisioned"
complete=1
for x in $datasets; do [ -e "$x" ] || complete=; done
if [ -z "$reset" ] && [ -e "$d/.provisioned" ] && [ -n "$complete" ]; then
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

shell_files() {
P="$d/shell/playground"
rm -rf "$d/shell"
mkdir -p "$P/projects/alpha/src" "$P/projects/beta/docs" "$P/notes" "$P/.config/app" "$P/archive/2023/q4"
echo "you found the hidden treasure" > "$P/.hidden-treasure"
printf '[app]\ntheme = dracula\n' > "$P/.config/app/settings.ini"
for y in 2024 2025; do
    for m in 01 02 03 04 05 06 07 08 09 10 11 12; do
        printf 'month,total\n%s-%s,%d\n' "$y" "$m" "$((10#$m * 100))" > "$P/notes/report-$y-$m.csv"
    done
done
: > "$P/notes/report-2024-draft.txt"
: > "$P/notes/meeting notes (final).txt"
: > "$P/notes/-i"
printf 'alpha: the first project\n' > "$P/projects/alpha/README"
printf 'int main(void) { return 0; }\n' > "$P/projects/alpha/src/main.c"
printf '# beta\n' > "$P/projects/beta/docs/index.md"
echo "old news" > "$P/archive/2023/q4/summary.txt"
ln -sfn projects/alpha "$P/current"
}

perms_files() {
R=/srv/lab/perms
rm -rf "$R"
mkdir -p "$R/private" "$R/listonly" "$R/enteronly" "$R/shared" "$R/sticky"
chmod 755 /srv/lab "$R"
echo "top secret" > "$R/private/secret.txt"
chmod 600 "$R/private/secret.txt"
chmod 700 "$R/private"
echo "you can see my name, but can you read me?" > "$R/listonly/visible.txt"
chmod 644 "$R/listonly/visible.txt"
chmod 744 "$R/listonly"
echo "you found me without being able to list the directory" > "$R/enteronly/known-name.txt"
chmod 644 "$R/enteronly/known-name.txt"
chmod 711 "$R/enteronly"
echo "alice's quarterly report" > "$R/report.txt"
chown alice:alice "$R/report.txt" 2>/dev/null
chmod 640 "$R/report.txt"
chmod 1777 "$R/sticky"
echo "alice was here" > "$R/sticky/alice.txt"
echo "bob was here" > "$R/sticky/bob.txt"
chown alice:alice "$R/sticky/alice.txt" 2>/dev/null
chown bob:bob "$R/sticky/bob.txt" 2>/dev/null
cat > "$R/whoami.c" <<'C'
#include <stdio.h>
#include <unistd.h>

int main(void) {
    printf("real uid: %d   effective uid: %d\n", (int)getuid(), (int)geteuid());
    return 0;
}
C
chmod 644 "$R/whoami.c"
}

procs_files() {
S="$d/procs"
rm -rf "$S"
mkdir -p "$S"
cat > "$S/sleeper.sh" <<'SH'
#!/usr/bin/env bash
echo "sleeper $$ started; send me signals with: kill -SIGNAL $$"
trap 'echo "[$$] SIGINT (Ctrl-C): ignoring it"' INT
trap 'echo "[$$] SIGHUP: pretending to reload my config"' HUP
trap 'echo "[$$] SIGUSR1: status report: all good"' USR1
trap 'echo "[$$] SIGTERM: cleaning up, then exiting"; exit 0' TERM
while true; do sleep 1; done
SH
cat > "$S/hog.sh" <<'SH'
#!/usr/bin/env bash
while :; do :; done
SH
cat > "$S/mystery.c" <<'C'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int read_name(const char *path, char *buf, size_t n) {
    FILE *f = fopen(path, "r");
    if (!f) return 0;
    if (!fgets(buf, (int)n, f)) { fclose(f); return 0; }
    fclose(f);
    buf[strcspn(buf, "\n")] = 0;
    return buf[0] != 0;
}

int main(void) {
    char name[128], path[512];
    const char *home = getenv("HOME");
    snprintf(path, sizeof path, "%s/.config/greeter/name", home ? home : "/");
    if (read_name("/etc/greeter/name", name, sizeof name) || read_name(path, name, sizeof name))
        printf("Hello, %s!\n", name);
    else
        printf("Hello, stranger.\n");
    return 0;
}
C
gcc -O2 -o "$S/mystery" "$S/mystery.c" 2>/dev/null && rm -f "$S/mystery.c"
chmod +x "$S/sleeper.sh" "$S/hog.sh"
}

toolbox_files() {
T="$d/toolbox"
rm -rf "$T"
mkdir -p "$T/tree/logs/old" "$T/tree/src/lib" "$T/tree/tmp" "$T/tree/docs"
printf 'dept,manager,floor\neng,Grace,3\nfinance,Katherine,2\nops,Linus,1\nresearch,Ada,4\nsales,Radia,1\nsupport,Ken,2\n' > "$T/depts.csv"
awk -F, '$4=="eng"{print $2" "$3}' /root/corpus/employees.csv | sort -u > "$T/eng.txt"
awk -F, '$4=="ops"{print $2" "$3}' /root/corpus/employees.csv | sort -u > "$T/ops.txt"
cat > "$T/app.conf" <<'CONF'
# app.conf
port = 8080
workers = 2
log_level = info
cache = off
CONF
cat > "$T/app.conf.new" <<'CONF'
# app.conf
port = 8080
workers = 8
log_level = warn
cache = on
cache_size = 256M
CONF
for i in 1 2 3 4 5; do echo "log line $i" > "$T/tree/logs/app-$i.log"; done
for i in 1 2 3; do echo "ancient $i" > "$T/tree/logs/old/app-old-$i.log"; touch -d "40 days ago" "$T/tree/logs/old/app-old-$i.log"; done
truncate -s 3M "$T/tree/logs/huge.log"
truncate -s 600K "$T/tree/tmp/cache.bin"
: > "$T/tree/tmp/empty.tmp"
printf 'int add(int a, int b) { return a + b; }\n' > "$T/tree/src/lib/add.c"
printf '#include <stdio.h>\nint main(void) { return 0; }\n' > "$T/tree/src/main.c"
printf 'print("hi")\n' > "$T/tree/src/tool.py"
printf '# Docs\n' > "$T/tree/docs/README.md"
: > "$T/tree/docs/notes with spaces.md"
}

git_files() {
G="$d/git"
rm -rf "$G"
mkdir -p "$G"
(
set -e
cd "$G"
git init -q -b main project
cd project
git config user.name "Nix Lab"
git config user.email "lab@nixlab.local"
n=0
commit() {
    n=$((n + 1))
    export GIT_AUTHOR_DATE="2025-03-$(printf %02d "$n")T10:00:00" GIT_COMMITTER_DATE="2025-03-$(printf %02d "$n")T10:00:00"
    git add -A
    git commit -q -m "$1"
}
cat > calc.sh <<'SH'
#!/usr/bin/env bash
add() { echo $(( $1 + $2 )); }
SH
printf '# calc\n\nA tiny calculator.\n' > README.md
commit "Start calc with add"
cat >> calc.sh <<'SH'
sub() { echo $(( $1 - $2 )); }
SH
commit "Add sub"
cat >> calc.sh <<'SH'
mul() { echo $(( $1 * $2 )); }
SH
commit "Add mul"
cat > test.sh <<'SH'
#!/usr/bin/env bash
source ./calc.sh
[ "$(add 2 3)" = 5 ] && [ "$(sub 9 4)" = 5 ] && [ "$(mul 6 7)" = 42 ]
SH
chmod +x calc.sh test.sh
commit "Add tests"
printf '# calc\n\nA tiny calculator for the shell.\n' > README.md
commit "Improve README wording"
git branch feature/greeting
cat >> calc.sh <<'SH'
div() { echo $(( $1 / $2 )); }
SH
commit "Add div"
sed -i 's/mul() { echo $(( $1 \* $2 )); }/mul() { echo $(( $1 * $2 + ($1 > 5) )); }/' calc.sh
cat >> calc.sh <<'SH'
square() { mul "$1" "$1"; }
SH
commit "Add square helper"
cat >> calc.sh <<'SH'
mod() { echo $(( $1 % $2 )); }
SH
commit "Add mod"
printf '# calc\n\nA tiny calculator for the shell.\n\nUsage: source calc.sh\n' > README.md
commit "Document usage"
cat >> calc.sh <<'SH'
pow() { echo $(( $1 ** $2 )); }
SH
commit "Add pow"
git checkout -q feature/greeting
printf '# calc\n\nA friendly little calculator. Hello!\n' > README.md
cat > greet.sh <<'SH'
#!/usr/bin/env bash
echo "Hello from calc"
SH
commit "Friendlier README and greeting"
git checkout -q main
echo "secret recipe: 2 parts add, 1 part mul" > recipe.txt
commit "Add secret recipe"
git reset -q --hard HEAD~1
cd "$G"
git clone -q --bare project remote.git
cd project
git remote add origin ../remote.git
git fetch -q origin
git branch -q -u origin/main main
)
}

archive_files() {
A="$d/archive"
rm -rf "$A"
mkdir -p "$A/release" "$A/site/css" "$A/site/img"
for f in moby-dick.txt sherlock.txt; do
    [ -e "/root/corpus/$f" ] && cp "/root/corpus/$f" "$A/release/"
done
cp /root/corpus/employees.csv /root/corpus/tickets.json "$A/release/"
(cd "$A/release" && sha256sum * > SHA256SUMS)
sed -i '5s/.*/THIS LINE WAS TAMPERED WITH/' "$A/release/employees.csv"
printf '<h1>hello</h1>\n' > "$A/site/index.html"
printf 'body { color: #bd93f9; }\n' > "$A/site/css/style.css"
head -c 20000 /dev/urandom > "$A/site/img/photo.jpg"
}

sql_files() {
Q="$d/sql"
rm -rf "$Q"
mkdir -p "$Q"
printf 'dept,manager,floor\neng,Grace,3\nfinance,Katherine,2\nops,Linus,1\nresearch,Ada,4\nsales,Radia,1\nsupport,Ken,2\n' > "$Q/depts.csv"
}

net_files() {
mkdir -p "$d/net"
cat > "$d/net/mknet.sh" <<'SH'
#!/usr/bin/env bash
www=/root/workbook-data/net/www
if [ "${1:-}" = --reset ]; then
    ip netns pids server 2>/dev/null | xargs -r kill 2>/dev/null
    ip netns del server 2>/dev/null
    ip link del lab0 2>/dev/null
    sleep 0.3
fi
if ip netns pids server 2>/dev/null | grep -q . && ip link show lab0 >/dev/null 2>&1; then
    exit 0
fi
ip netns pids server 2>/dev/null | xargs -r kill 2>/dev/null
ip netns del server 2>/dev/null
ip link del lab0 2>/dev/null
mkdir -p "$www"
[ -s "$www/blob.bin" ] || head -c 2000000 /dev/urandom > "$www/blob.bin"
[ -s "$www/index.html" ] || echo '<h1>hello from the server namespace</h1>' > "$www/index.html"
ip netns add server
ip link add lab0 type veth peer name srv0
ip link set srv0 netns server
ip addr add 10.10.0.1/24 dev lab0
ip link set lab0 up
ip -n server addr add 10.10.0.2/24 dev srv0
ip -n server link set srv0 up
ip -n server link set lo up
ip netns exec server setsid -f python3 -m http.server 8000 --directory "$www" >/dev/null 2>&1
ip netns exec server setsid -f socat TCP-LISTEN:9000,fork,reuseaddr EXEC:cat >/dev/null 2>&1
ip netns exec server setsid -f "$(command -v sshd)" -f /etc/ssh/sshd_config -o PidFile=none >/dev/null 2>&1
for _ in 1 2 3 4 5 6 7 8 9 10; do
    ip netns exec server ss -tln | grep -q ':8000 ' && break
    sleep 0.2
done
SH
chmod +x "$d/net/mknet.sh"
cat > "$d/net/mkroute.sh" <<'SH'
#!/usr/bin/env bash
nss="client router web mallory"
www=/root/workbook-data/net/www
down() {
    for n in $nss; do
        ip netns pids "$n" 2>/dev/null | xargs -r kill 2>/dev/null
        ip netns del "$n" 2>/dev/null
    done
    sleep 0.3
}
[ "${1:-}" = --reset ] && down
ok=1
for n in $nss; do ip netns pids "$n" >/dev/null 2>&1 || ok=; done
ip netns exec web ss -tln 2>/dev/null | grep -q ':8000 ' || ok=
[ -n "$ok" ] && exit 0
down
mkdir -p "$www"
[ -s "$www/index.html" ] || echo '<h1>hello from the server namespace</h1>' > "$www/index.html"
for n in $nss; do
    ip netns add "$n"
    ip -n "$n" link set lo up
done
ip -n router link add br0 type bridge
ip -n router link set br0 up
ip -n router addr add 10.1.0.1/24 dev br0
for pair in client:10.1.0.2 mallory:10.1.0.66; do
    n=${pair%%:*}
    ip link add "$n-eth0" netns "$n" type veth peer name "to-$n" netns router
    ip -n "$n" link set "$n-eth0" name eth0
    ip -n "$n" addr add "${pair#*:}/24" dev eth0
    ip -n "$n" link set eth0 up
    ip -n router link set "to-$n" master br0 up
    ip -n "$n" route add default via 10.1.0.1
done
ip link add web-eth0 netns web type veth peer name to-web netns router
ip -n web link set web-eth0 name eth0
ip -n web addr add 10.2.0.2/24 dev eth0
ip -n web addr add 10.2.0.3/24 dev eth0
ip -n web link set eth0 up
ip -n web route add default via 10.2.0.1
ip -n router addr add 10.2.0.1/24 dev to-web
ip -n router link set to-web up
ip netns exec router sysctl -qw net.ipv4.ip_forward=1
ip netns exec web setsid -f python3 -m http.server 8000 --directory "$www" >/dev/null 2>&1
ip netns exec web setsid -f socat -u UDP-RECV:514,bind=10.2.0.3 OPEN:/root/workbook-data/net/syslog.txt,creat,append >/dev/null 2>&1
for _ in 1 2 3 4 5 6 7 8 9 10; do
    ip netns exec web ss -tln | grep -q ':8000 ' && break
    sleep 0.2
done
SH
chmod +x "$d/net/mkroute.sh"
}

sec_files() {
S=/opt/scenario
rm -rf "$S"; mkdir -p "$S/bin" "$S/jobs" "$S/backups" "$S/.quiet"
chmod 755 /opt "$S" "$S/bin"

# --- hole 1: bob may run a "maintenance tool" as root; it is really perl -----
grep -q '^@includedir /etc/sudoers.d' /etc/sudoers 2>/dev/null || \
  printf '\n@includedir /etc/sudoers.d\n' >> /etc/sudoers
mkdir -p /etc/sudoers.d
ln -sf "$(command -v perl)" "$S/bin/dbmaint"
printf 'bob ALL=(root) NOPASSWD: /opt/scenario/bin/dbmaint\n' > /etc/sudoers.d/90-scenario
chmod 440 /etc/sudoers.d/90-scenario

# --- hole 2: a setuid-root helper that trusts PATH and copies argv in -----
cat > "$S/bin/syscheck.c" <<'EOF'
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
void banner(char *name){ char b[64]; strcpy(b, name); printf("checking %s\n", b); }
int main(int argc, char **argv){
    setuid(0); setgid(0);
    if (argc > 1) banner(argv[1]);
    system("uptime; free -h | head -2");          /* uptime/free by name: PATH is trusted */
    return 0;
}
EOF
cc_opts="-w -fno-stack-protector -no-pie -z execstack -g"
if command -v gcc >/dev/null; then gcc $cc_opts "$S/bin/syscheck.c" -o "$S/bin/syscheck"
else cc $cc_opts "$S/bin/syscheck.c" -o "$S/bin/syscheck"; fi
chown root:root "$S/bin/syscheck"; chmod 4755 "$S/bin/syscheck"
chmod 600 "$S/bin/syscheck.c"

# --- memory-safety target for E25.12/E25.13 (source world-readable) --------
cat > "$S/bin/echoback.c" <<'EOF'
#include <stdio.h>
#include <string.h>
static void vuln(const char *s){ char buf[64]; strcpy(buf, s); }
int main(int argc, char **argv){ if (argc > 1) vuln(argv[1]); puts("done"); return 0; }
EOF
gcc -w -fno-stack-protector -no-pie -z execstack -g "$S/bin/echoback.c" -o "$S/bin/echoback" 2>/dev/null   || cc -w -g "$S/bin/echoback.c" -o "$S/bin/echoback"
chmod 755 "$S/bin/echoback" "$S/bin/echoback.c"

# --- hole 3: a capability on a file-reading helper ------------------------
cp "$(command -v cat)" "$S/bin/readlog"
setcap cap_dac_read_search+ep "$S/bin/readlog" 2>/dev/null

# --- hole 4: a world-writable "cron" job that root runs -------------------
cat > "$S/jobs/collect.sh" <<'EOF'
#!/bin/sh
# pretend-cron: runs as root every few minutes to collect stats
date >> /opt/scenario/backups/stats.log
EOF
chmod 777 "$S/jobs/collect.sh"

# --- hole 5: secrets left at rest -----------------------------------------
cat > "$S/backups/db-backup.sql" <<'EOF'
-- nightly dump
CREATE USER 'svc'@'%' IDENTIFIED BY 'Pr0d-DB-pw!2026';
EOF
chmod 644 "$S/backups/db-backup.sql"
touch "$S/.provisioned"
}

binexp_files() {
B=/opt/binexp
rm -rf "$B"; mkdir -p "$B/bin"; chmod 755 /opt "$B" "$B/bin"
echo 'FLAG{lab-only-practice-flag}' > "$B/flag.txt"; chmod 644 "$B/flag.txt"
V="-w -fno-stack-protector -no-pie -fcf-protection=none -g"
cat > "$B/bin/ret2win.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>
void win(void){ puts("WIN: you redirected control to win()"); fflush(stdout); }
void vuln(void){ char buf[64]; puts("name?"); fflush(stdout); gets(buf); }
int main(void){ setbuf(stdout,0); vuln(); puts("normal return"); return 0; }
EOF
gcc $V "$B/bin/ret2win.c" -o "$B/bin/ret2win" 2>/dev/null
cat > "$B/bin/leak.c" <<'EOF'
#include <stdio.h>
#include <string.h>
void vuln(void){
  char buf[64];
  printf("echo> "); fflush(stdout);
  read(0, buf, 200);
  printf("you said: %s\n", buf);
  fflush(stdout);
}
int main(void){ setbuf(stdout,0); vuln(); return 0; }
EOF
gcc -w -fstack-protector-all -no-pie -fcf-protection=none -g "$B/bin/leak.c" -o "$B/bin/leak" 2>/dev/null
cat > "$B/bin/oobw.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>
void win(void){ puts("WIN: out-of-bounds write flipped the guard"); fflush(stdout); }
int main(void){
  long table[8]; long guard = 0;
  long idx, val;
  setbuf(stdout,0);
  puts("idx val?");
  if (scanf("%ld %ld", &idx, &val)!=2) return 1;
  table[idx] = val;
  if (guard == 0xc0ffee) win();
  else puts("guard intact");
  return 0;
}
EOF
gcc $V "$B/bin/oobw.c" -o "$B/bin/oobw" 2>/dev/null
cat > "$B/bin/ropme.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>
__asm__(".global useful_gadgets\n useful_gadgets:\n pop %rdi\n ret\n pop %rsi\n pop %rdx\n ret\n");
void print_flag(long key){
  if (key != 0xc0ffee){ puts("wrong key"); return; }
  FILE *f=fopen("/opt/binexp/flag.txt","r"); char b[64];
  if(f){ fgets(b,64,f); printf("FLAG: %s", b); fclose(f); }
  fflush(stdout);
}
void vuln(void){ char buf[64]; read(0,buf,256); }
int main(void){ setbuf(stdout,0); vuln(); return 0; }
EOF
gcc $V "$B/bin/ropme.c" -o "$B/bin/ropme" 2>/dev/null
cat > "$B/bin/aslr.c" <<'EOF'
#include <stdio.h>
__asm__(".global useful_gadgets\n useful_gadgets:\n pop %rdi\n ret\n pop %rsi\n pop %rdx\n ret\n");
void vuln(void){ char buf[64]; read(0,buf,256); }
int main(void){ setbuf(stdout,0); puts("go"); vuln(); return 0; }
EOF
gcc $V "$B/bin/aslr.c" -o "$B/bin/aslr" 2>/dev/null
chmod 755 "$B/bin"/* 2>/dev/null
touch "$B/.provisioned"
}

want() { [ -n "$reset" ] || [ ! -e "$1" ]; }

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
want "$d/shell" && shell_files
want /srv/lab/perms && perms_files
want "$d/procs" && procs_files
want "$d/toolbox" && toolbox_files
want "$d/git" && git_files
want "$d/archive" && archive_files
want "$d/sql" && sql_files
want "$d/net/mkroute.sh" && net_files
want /opt/scenario/.provisioned && sec_files
want /opt/binexp/.provisioned && binexp_files

touch "$d/.provisioned"
echo "corpus:"; ls -1 /root/corpus
echo; echo "workbook-data:"; ls "$d"
echo; echo "Setup complete."
