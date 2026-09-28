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
