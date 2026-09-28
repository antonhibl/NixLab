pkgs: with pkgs; [
  # editors
  emacs-nox
  neovim
  nano

  # shell tools
  gawk
  gnused
  gnugrep
  ripgrep
  coreutils
  bashInteractive
  bash-completion
  blesh
  ncurses

  # languages
  gcc
  gnumake
  cmake
  pkg-config
  gdb
  clang-tools
  bear
  valgrind
  binutils
  # Python
  (python313.withPackages (ps: with ps; [ ipython requests debugpy ]))
  # Go
  go
  gopls
  # Perl
  perl
  # Common Lisp
  sbcl

  # neovim language servers, formatters, and helpers
  lua-language-server
  bash-language-server
  neocmakelsp
  pyright
  ruff
  black
  vscode-langservers-extracted
  yaml-language-server
  taplo
  marksman
  markdownlint-cli2
  markdown-toc
  prettier
  stylua
  shfmt
  gotools
  gofumpt
  delve
  cmake-format
  nodejs
  lazygit
  fd
  fzf
  unzip

  # system, processes, and debugging the OS
  procps
  psmisc
  util-linux
  htop
  strace
  ltrace
  lsof
  sysstat
  hyperfine
  perf
  time
  ncdu
  audit
  libcap
  acl
  shadow
  sudo
  which
  man-db

  # files, archives, and text
  findutils
  diffutils
  patch
  gnutar
  gzip
  bzip2
  xz
  zstd
  zip
  sqlite-interactive
  bat
  eza
  zoxide

  # networking
  openssh
  iproute2
  iputils
  dig
  netcat-openbsd
  socat
  curl
  rsync
  tcpdump

  # common helpers
  jq
  git
  yazi
  tmux
  file
  tree
  ripgrep
  shellcheck
  man-pages
  man-pages-posix
]
