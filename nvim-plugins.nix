{ pkgs, dracula-nvim }:
let
  vp = pkgs.vimPlugins;
  ts = vp.nvim-treesitter;
  plugins = {
    "LazyVim" = vp.LazyVim;
    "lazy.nvim" = vp.lazy-nvim;
    "SchemaStore.nvim" = vp.SchemaStore-nvim;
    "blink.cmp" = vp.blink-cmp;
    "bufferline.nvim" = vp.bufferline-nvim;
    "catppuccin" = vp.catppuccin-nvim;
    "clangd_extensions.nvim" = vp.clangd_extensions-nvim;
    "cmake-tools.nvim" = vp.cmake-tools-nvim;
    "conform.nvim" = vp.conform-nvim;
    "dashboard-nvim" = vp.dashboard-nvim;
    "dial.nvim" = vp.dial-nvim;
    "dracula.nvim" = dracula-nvim;
    "flash.nvim" = vp.flash-nvim;
    "friendly-snippets" = vp.friendly-snippets;
    "gitsigns.nvim" = vp.gitsigns-nvim;
    "grug-far.nvim" = vp.grug-far-nvim;
    "lazydev.nvim" = vp.lazydev-nvim;
    "lualine.nvim" = vp.lualine-nvim;
    "markdown-preview.nvim" = vp.markdown-preview-nvim;
    "mini.ai" = vp.mini-ai;
    "mini.hipatterns" = vp.mini-hipatterns;
    "mini.icons" = vp.mini-icons;
    "mini.pairs" = vp.mini-pairs;
    "noice.nvim" = vp.noice-nvim;
    "nui.nvim" = vp.nui-nvim;
    "nvim-dap" = vp.nvim-dap;
    "nvim-dap-go" = vp.nvim-dap-go;
    "nvim-dap-python" = vp.nvim-dap-python;
    "nvim-dap-ui" = vp.nvim-dap-ui;
    "nvim-dap-virtual-text" = vp.nvim-dap-virtual-text;
    "nvim-lint" = vp.nvim-lint;
    "nvim-lspconfig" = vp.nvim-lspconfig;
    "nvim-nio" = vp.nvim-nio;
    "nvim-treesitter" = ts;
    "nvim-treesitter-textobjects" = vp.nvim-treesitter-textobjects;
    "nvim-ts-autotag" = vp.nvim-ts-autotag;
    "persistence.nvim" = vp.persistence-nvim;
    "plenary.nvim" = vp.plenary-nvim;
    "render-markdown.nvim" = vp.render-markdown-nvim;
    "snacks.nvim" = vp.snacks-nvim;
    "todo-comments.nvim" = vp.todo-comments-nvim;
    "tokyonight.nvim" = vp.tokyonight-nvim;
    "trouble.nvim" = vp.trouble-nvim;
    "ts-comments.nvim" = vp.ts-comments-nvim;
    "venv-selector.nvim" = vp.venv-selector-nvim;
    "vim-illuminate" = vp.vim-illuminate;
    "vim-startuptime" = vp.vim-startuptime;
    "which-key.nvim" = vp.which-key-nvim;
    "yanky.nvim" = vp.yanky-nvim;
    "yazi.nvim" = vp.yazi-nvim;
  };
  langs = [
    "awk" "bash" "c" "cmake" "commonlisp" "cpp" "css" "diff" "dockerfile"
    "git_config" "git_rebase" "gitattributes" "gitcommit" "gitignore"
    "go" "gomod" "gosum" "gowork" "html" "javascript" "jsdoc" "json" "json5"
    "lua" "luadoc" "luap" "make" "markdown" "markdown_inline" "ninja" "nix"
    "perl" "printf" "python" "query" "regex" "rst" "sql" "toml" "tsx"
    "typescript" "vim" "vimdoc" "xml" "yaml"
  ];
  queryOnly = [ "ecma" "html_tags" "jsx" ];
in
{
  plugins = pkgs.linkFarm "nixlab-nvim-plugins" plugins;
  treesitter = pkgs.symlinkJoin {
    name = "nixlab-nvim-treesitter";
    paths = map (l: ts.parsers.${l}) langs ++ map (l: ts.queries.${l}) (langs ++ queryOnly);
  };
}
