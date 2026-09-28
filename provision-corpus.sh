#!/usr/bin/env bash
# provision-corpus.sh DEST — build the practice corpus into DEST.
# Single source of truth for the corpus across AWS / local VM / Docker.
# Best-effort book downloads; synthetic data always generated. Idempotent
# via a sentinel. Needs: curl, awk (gawk or mawk), coreutils. ps/ip optional.
set -u
dest="${1:-/root/corpus}"
mkdir -p "$dest"
sentinel="$dest/.provisioned"
[ -e "$sentinel" ] && { echo "corpus already provisioned at $dest"; exit 0; }

# --- real prose: a few Project Gutenberg plain-text books (best-effort) -----
get() { curl -fsSL --max-time 60 "$1" -o "$2" 2>/dev/null || echo "corpus: skipped $(basename "$2") (offline?)"; }
get https://www.gutenberg.org/cache/epub/2701/pg2701.txt "$dest/moby-dick.txt"
get https://www.gutenberg.org/cache/epub/1661/pg1661.txt "$dest/sherlock.txt"
get https://www.gutenberg.org/cache/epub/1342/pg1342.txt "$dest/pride.txt"
get https://www.gutenberg.org/cache/epub/100/pg100.txt   "$dest/shakespeare.txt"

# If every download failed (offline build), leave a tiny prose stand-in so the
# prose exercises still have *something* to chew on.
if ! ls "$dest"/*.txt >/dev/null 2>&1; then
  cat > "$dest/sherlock.txt" <<'PROSE'
To Sherlock Holmes she is always THE woman.
"You see, but you do not observe," said Holmes.
It was a most singular and extraordinary murder, Watson.
London lay before them, vast and grey and indifferent.
PROSE
  cp "$dest/sherlock.txt" "$dest/moby-dick.txt"
fi

# --- synthetic columnar data (always) ---------------------------------------
awk 'BEGIN{
  srand(42);
  split("eng sales ops finance research support",D," ");
  split("Ada Alan Grace Linus Ken Dennis Barbara Margaret Katherine Radia",F," ");
  split("Lovelace Turing Hopper Torvalds Thompson Ritchie Liskov Hamilton Johnson Perlman",L," ");
  print "id,first,last,dept,salary,hired";
  for(i=1;i<=1000;i++){
    f=F[int(rand()*10)+1]; l=L[int(rand()*10)+1]; d=D[int(rand()*6)+1];
    sal=45000+int(rand()*90000);
    y=2008+int(rand()*17); m=1+int(rand()*12); day=1+int(rand()*28);
    printf "%d,%s,%s,%s,%d,%04d-%02d-%02d\n", i,f,l,d,sal,y,m,day;
  }
}' > "$dest/employees.csv"

awk 'BEGIN{
  srand(7);
  split("200 200 200 200 301 404 500 403 200 206",S," ");
  split("/ /index.html /login /api/users /static/app.js /favicon.ico /search /images/logo.png /about /api/orders",P," ");
  split("GET GET GET POST GET GET HEAD GET PUT DELETE",M," ");
  for(i=0;i<2000;i++){
    ip=(1+int(rand()*223))"."int(rand()*256)"."int(rand()*256)"."(1+int(rand()*254));
    d=1+int(rand()*28); h=int(rand()*24); mi=int(rand()*60); se=int(rand()*60);
    idx=int(rand()*10)+1; bytes=int(rand()*8000);
    printf "%s - - [%02d/Jan/2026:%02d:%02d:%02d +0000] \"%s %s HTTP/1.1\" %s %d\n",
           ip,d,h,mi,se,M[idx],P[idx],S[idx],bytes;
  }
}' > "$dest/access.log"

awk 'BEGIN{
  srand(3); split("open closed pending",ST," ");
  print "[";
  for(i=1;i<=200;i++){
    st=ST[int(rand()*3)+1]; pr=1+int(rand()*5); sep=(i<200)?",":"";
    printf "  {\"id\":%d,\"status\":\"%s\",\"priority\":%d,\"assignee\":\"user%d\"}%s\n",
           i,st,pr,1+int(rand()*20),sep;
  }
  print "]";
}' > "$dest/tickets.json"

{ ps aux 2>/dev/null; echo; ip -o addr 2>/dev/null; } > "$dest/system-snapshot.txt" 2>/dev/null || true

cat > "$dest/README.txt" <<'GUIDE'
Practice corpus for awk / sed / grep / regex / perl / python / C.
  *.txt              prose  -> word counts, regex, line edits
  employees.csv      columns-> awk -F, field work, group-by
  access.log         logs   -> regex capture, status-code tallies
  tickets.json       json   -> jq / python, and sed/awk on structured text
  system-snapshot.txt messy -> real ps/ip output to slice up
See workbook.org for the guided exercises.
GUIDE

touch "$sentinel"
echo "corpus: provisioned -> $dest"
