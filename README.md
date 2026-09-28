# nixlab

Disposable Linux labs on your Mac for learning the command line, five
programming languages, two editors, and their debuggers, by doing.

Each lab is a lightweight Linux VM started with Apple's
[`container`](https://github.com/apple/container). It comes with a pinned Nix
toolchain, a practice corpus, fully configured Emacs and Neovim, and a workbook
of over 100 exercises you work through from inside the editor. Labs start in
seconds, work offline, and can be thrown away and recreated whenever you like.

## Goals

- **Learn by doing.** The workbook is a set of tasks against real data, not a
  textbook. Every exercise has a folded hint and a runnable solution.
- **Zero setup.** Everything a lab needs is baked into the image: tools, data,
  editor configs, editor packages, language servers. Nothing downloads when a
  lab starts.
- **Reproducible.** The toolchain, Neovim plugins and treesitter parsers come
  from Nix and are pinned by `flake.lock`. Emacs packages are fetched once,
  at image build time.
- **Disposable.** Break a lab, delete it, make a new one. Your work in a lab
  survives stops and restarts until you remove it.

## Requirements

- A Mac with Apple silicon.
- macOS 26 or later (required by `container`).
- [`container`](https://github.com/apple/container/releases): install the
  signed package from its releases page, then run `container system start`
  once. The lab script also starts it for you if it isn't running.
- Several GB of free disk space for the image and your labs.
- Internet access while building the image (Nix packages, Emacs packages, and
  the public-domain books in the corpus). Labs themselves work offline.
- A terminal with Nerd Font icons and 256 colours. See below.

### Recommended terminal: Ghostty

[Ghostty](https://ghostty.org) ships the Nerd Font symbols built in, so the
icons in Neovim, Dirvish, yazi and lazygit render with no font setup at all.
Add this to `~/.config/ghostty/config` so the Option key works as Meta
(`M-x` and friends in Emacs):

```
macos-option-as-alt = true
```

Other terminals work too if you give them a Nerd Font, for example
`nerd-fonts.symbols-only` or `nerd-fonts.jetbrains-mono` from nixpkgs. WezTerm
and kitty also include the symbols by default. In Terminal.app or iTerm2,
enable mouse reporting and "Use Option as Meta key".

## Quick start

```bash
git clone https://github.com/<you>/nixlab.git
cd nixlab
./container-lab.sh build      # once: builds the image (takes a while the first time)
./container-lab.sh new first  # create a lab called "first" and open a shell in it
```

Inside the lab:

```bash
emacs -nw     # dashboard opens; press w for the workbook
nvim          # or Neovim, if you prefer
```

New to Emacs or Vim? Start with track 0 of the workbook. It assumes nothing and
teaches you enough of both editors to do everything else.

## The workbook

`workbook.org` is an Org file of 193 exercises. Code blocks run in place
(`SPC c c` in Emacs), and every exercise has a folded hint and solution.

| Track | Topic |
|---|---|
| 0 | Emacs & Vim fundamentals: Evil, Org, Babel, help, SLIME, structural editing |
| 1 | tmux: sessions that survive, windows, panes, copy mode, scripting a workspace |
| 2 | Shell & filesystem: navigation, links, globbing, quoting, redirection, jobs, history, man |
| 3 | Users & permissions: chmod, chown, umask, sudo, setuid, sticky bit, ACLs, capabilities |
| 4 | Processes & signals: ps, top, kill, nice, /proc, lsof, strace |
| 5 | Finding files & the text toolbox: find, xargs, sort, uniq, cut, join, comm, diff, patch, jq |
| 6 | grep & egrep |
| 7 | sed |
| 8 | awk |
| 9 | bash scripting |
| 10 | Git: branches, merge vs rebase, blame, stash, reflog, bisect, remotes |
| 11 | Archives & integrity: tar, gzip, xz, zstd, zip, sha256sum |
| 12 | Networking & SSH: ip, dig, curl, ss, nc, SSH keys, tunnels, rsync, tcpdump |
| 13 | The modern command line: fzf, ripgrep, fd, bat, eza, zoxide, yazi, lazygit |
| 14 | Observability & performance: time, free, df, du, vmstat, iostat, hyperfine, perf |
| 15 | Auditing with auditd: auditctl, file watches, syscall rules, ausearch, aureport |
| 16 | SQLite: importing CSV and logs, GROUP BY, JOIN, indexes, JSON, Python |
| 17 | perl |
| 18 | python |
| 19 | C: warnings, valgrind, sanitizers, make, cmake, clangd |
| 20 | Emacs & Elisp |
| 21 | Nix |
| 22 | Common Lisp |
| 23 | Debuggers: gdb, pdb, Delve, Edebug, the SLIME debugger |
| Capstone | One question answered with every tool |

Practice data lives in `/root/corpus` (books, CSV, logs, JSON). Exercise inputs
are generated in `/root/workbook-data` the first time a lab starts.

## Using labs

```bash
./container-lab.sh new NAME     # create a lab and open a shell in it
./container-lab.sh enter NAME   # open a shell in a lab (starts it if stopped)
./container-lab.sh attach NAME  # enter the lab's tmux session "main" (creates it if needed)
./container-lab.sh stop NAME    # stop a lab; its files are kept
./container-lab.sh start NAME   # start it again and open a shell
./container-lab.sh ls           # list labs
./container-lab.sh rm NAME      # delete a lab and its files
./container-lab.sh teardown     # delete every lab, their files, and the image
```

Each lab's `/root` is its own volume: your work survives `stop` and `start`,
and `rm` wipes it.

Settings, as environment variables:

| Variable | Default | Meaning |
|---|---|---|
| `NIXLAB_CPUS` | `4` | vCPUs per lab |
| `NIXLAB_MEM` | `4G` | memory per lab |
| `NIXLAB_BUILD_MEM` | `4G` | memory for the image builder |
| `NIXLAB_DNS` | `1.1.1.1` | DNS server for builds and labs (`""` uses container's default) |
| `NIXLAB_IMAGE` | `nixlab:latest` | image tag |

## What's in a lab

**Languages and tools:** bash, coreutils, findutils, gawk, sed, grep, ripgrep,
fd, fzf, bat, eza, zoxide, jq, SQLite, git, lazygit, yazi, tmux, Python 3.13,
Perl, Go, C (gcc, clang tools, make, cmake, gdb, valgrind), SBCL. System tools:
strace, ltrace, lsof, htop, sysstat, perf, hyperfine, auditd, and networking
with OpenSSH, iproute2, dig, curl, netcat, socat, rsync and tcpdump. The full
list is in `toolchain.nix`.

**Users and services:** you work as `root`. Two ordinary users, `alice` (in
`wheel`, may use `sudo`) and `bob`, exist for the permissions track. Every lab
runs an SSH server, so two labs can log in to each other for the networking
track. `auditd` is configured but not started until track 15 asks for it.

**Capabilities:** labs are created with `--cap-add ALL`, which `strace`,
`perf`, `auditctl`, `tcpdump` and setuid programs need. That's safe here
because every lab is its own virtual machine, not a container sharing your
Mac's kernel.

**Emacs** (`init.el`): Evil with `SPC` as the leader key, Ivy/Counsel,
helpful (`SPC h` for help), Company, Org Babel for shell, Python, Perl, C, Go,
awk, sed, SQLite, Elisp and Common Lisp, SLIME with paredit, Dirvish, and a lab
dashboard. Dracula theme, with tardis-theme installed. Built for `emacs -nw`
and never binds `C-h` or `C-l`.

**Neovim** (`nvim/`): LazyVim with extras for C, CMake, Go, Python, JSON,
Markdown, YAML and TOML. Plugins, treesitter parsers and language servers all
come from Nix, and Mason is switched off, so nothing is downloaded at runtime.
Debugging works for C (gdb), Go (Delve) and Python (debugpy).

## How it works

- `Dockerfile` builds one image: it installs `toolchainEnv` from `flake.nix`,
  builds the Neovim plugin and parser sets from `nvim-plugins.nix`, generates
  the corpus, and pre-installs the Emacs packages.
- Everything meant for `/root` is staged in `/opt/nixlab/skel`. `container`
  mounts an empty volume over each lab's `/root`, so `lab-entrypoint.sh` copies
  the skeleton in on every start, only adding files that are missing. Your edits
  are never overwritten.
- `lab-entrypoint.sh` then runs `workbook-setup.sh`, which creates the exercise
  inputs once. `workbook-setup.sh --reset` restores them.
- The first `build` writes `flake.lock` into the repository. Later builds reuse
  it, so the image stays the same until you choose to update.

## Customizing

- **Add a tool:** add it to `toolchain.nix`, then rebuild.
- **Add a Neovim plugin:** add its spec under `nvim/lua/plugins/`, and add its
  lazy.nvim name and nixpkgs package to `nvim-plugins.nix`. Language servers go
  in `toolchain.nix`.
- **Add an Emacs package:** add it to `nixlab-packages` in `init.el`.
- **Update everything:** delete `flake.lock`, then rebuild.

New labs pick up changes after a rebuild. Existing labs keep their own copies
of `workbook.org` and the editor configs. To refresh one, delete the file in the
lab and restart it, or `rm` the lab and create it again.

## Troubleshooting

- **`Could not resolve host` during the build:** the builder VM needs DNS. The
  script passes `NIXLAB_DNS`. If it still fails, check that a VPN or firewall
  (Little Snitch, LuLu) isn't blocking `container`'s network.
- **Emacs starts without Evil or the dashboard:** `HOME` is wrong. Shells
  opened by `container-lab.sh` set it; with a raw `container exec`, pass
  `-e HOME=/root`.
- **Boxes instead of icons:** your terminal has no Nerd Font. See
  [Recommended terminal](#recommended-terminal-ghostty).
- **The mouse wheel doesn't scroll in Emacs:** turn on mouse reporting in your
  terminal (Ghostty does this by default).

## Repository layout

| Path | Purpose |
|---|---|
| `container-lab.sh` | create, enter, stop, start, list and remove labs; build the image |
| `Dockerfile` | the lab image |
| `flake.nix`, `flake.lock` | the pinned toolchain, Neovim plugins and parsers |
| `toolchain.nix` | every tool installed in a lab |
| `nvim-plugins.nix` | Neovim plugins and treesitter parsers from nixpkgs |
| `init.el` | the lab's Emacs config |
| `bashrc` | the lab's shell: prompt, colours, aliases, completion |
| `tmux.conf` | the lab's tmux: mouse, vi copy mode, pane keys, Dracula colours |
| `nvim/` | the lab's Neovim config |
| `workbook.org` | the exercises |
| `provision-corpus.sh` | builds the practice corpus |
| `workbook-setup.sh` | builds the exercise inputs in `/root/workbook-data` |
| `lab-entrypoint.sh` | runs on every lab start |
| `nixlab.el` | older Docker-era Emacs front-end, not yet ported to `container` |
