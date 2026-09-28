# Dockerfile
FROM nixos/nix:latest

RUN mkdir -p /etc/nix && \
    printf 'experimental-features = nix-command flakes\n' >> /etc/nix/nix.conf

WORKDIR /opt/nixlab
COPY flake.* toolchain.nix nvim-plugins.nix provision-corpus.sh lab-entrypoint.sh workbook-setup.sh ./
RUN nix flake lock

# bake the toolchain in
RUN nix profile install --priority 4 .#toolchainEnv && \
    ln -sfn "$(readlink -f /root/.nix-profile)" /nix/var/nix/profiles/nixlab && \
    nix build .#nvimPlugins -o /opt/nixlab/nvim-plugins && \
    nix build .#nvimTreesitter -o /opt/nixlab/nvim-treesitter && \
    nix store gc
ENV PATH=/nix/var/nix/profiles/nixlab/bin:${PATH} \
    NIXLAB_NVIM_PLUGINS=/opt/nixlab/nvim-plugins \
    NIXLAB_TS_DIR=/opt/nixlab/nvim-treesitter

# home skeleton
RUN mkdir -p skel/.emacs.d && bash provision-corpus.sh skel/corpus
# COPY sources are paths in the project dir, not the image
COPY init.el skel/.emacs.d/init.el
COPY bashrc skel/.bashrc
RUN printf '[ -f ~/.bashrc ] && . ~/.bashrc\n' > skel/.bash_profile
COPY nvim skel/.config/nvim
COPY workbook.org skel/workbook.org
# prefetch Emacs packages so labs start offline and instantly
RUN HOME=/opt/nixlab/skel emacs --batch -l /opt/nixlab/skel/.emacs.d/init.el \
   || echo "warning: emacs package prefetch failed; packages will install on first launch"
RUN HOME=/tmp/nvimcheck XDG_CONFIG_HOME=/opt/nixlab/skel/.config \
    nvim --headless "+lua io.write(#require('lazy').plugins() .. ' neovim plugins loaded\n')" +qa || true
RUN chmod a+x lab-entrypoint.sh workbook-setup.sh
WORKDIR /root
ENV HOME=/root \
    LANG=C.UTF-8 \
    EDITOR=nvim
ENTRYPOINT ["/opt/nixlab/lab-entrypoint.sh"]
CMD ["bash", "-l"]
