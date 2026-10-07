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
ENV PATH=/usr/local/bin:/nix/var/nix/profiles/nixlab/bin:${PATH} \
    NIXLAB_NVIM_PLUGINS=/opt/nixlab/nvim-plugins \
    NIXLAB_TS_DIR=/opt/nixlab/nvim-treesitter

RUN for f in /etc/passwd /etc/group /etc/shadow /etc/gshadow /etc/sudoers /etc/pam.d /etc/ssh /etc/audit; do \
        if [ -L "$f" ]; then t=$(readlink -f "$f"); rm "$f"; if [ -e "$t" ]; then cp -rL "$t" "$f"; chmod -R u+w "$f"; fi; fi; \
    done && \
    mkdir -p /home /usr/local/bin /var/empty /etc/ssh /etc/audit /var/log/audit /etc/pam.d /var/db/sudo && \
    chmod 755 /var/empty && \
    { pwconv 2>/dev/null; grpconv 2>/dev/null; true; } && \
    groupadd -f wheel && groupadd -f devs && \
    useradd -m -U -s /nix/var/nix/profiles/nixlab/bin/bash -G wheel,devs alice && \
    useradd -m -U -s /nix/var/nix/profiles/nixlab/bin/bash -G devs bob && \
    useradd -r -d /var/empty -s "$(command -v nologin)" sshd && \
    install -o root -g root -m 4755 "$(readlink -f "$(command -v sudo)")" /usr/local/bin/sudo && \
    printf 'auth sufficient pam_rootok.so\nauth required pam_deny.so\naccount required pam_permit.so\nsession required pam_permit.so\n' > /etc/pam.d/sudo && \
    printf 'root ALL=(ALL:ALL) ALL\n%%wheel ALL=(ALL:ALL) NOPASSWD: ALL\n' > /etc/sudoers && \
    chmod 440 /etc/sudoers && \
    printf 'Port 22\nHostKey /etc/ssh/ssh_host_ed25519_key\nPermitRootLogin yes\nPasswordAuthentication yes\nKbdInteractiveAuthentication no\nUsePAM no\nAllowTcpForwarding yes\nX11Forwarding no\nPrintMotd no\nSubsystem sftp internal-sftp\n' > /etc/ssh/sshd_config && \
    printf 'local_events = yes\nwrite_logs = yes\nlog_file = /var/log/audit/audit.log\nlog_format = ENRICHED\nflush = INCREMENTAL_ASYNC\nfreq = 50\nmax_log_file = 8\nnum_logs = 5\nmax_log_file_action = ROTATE\nspace_left = 75\nspace_left_action = SYSLOG\nadmin_space_left = 50\nadmin_space_left_action = SUSPEND\ndisk_full_action = SUSPEND\ndisk_error_action = SUSPEND\n' > /etc/audit/auditd.conf && \
    mkdir -p /var/cache/man/nixlab && mandb -q && apropos -l compress | head -3
RUN setpriv --reuid=alice --regid=alice --init-groups /usr/local/bin/sudo -n id -un 2>&1 | sed 's/^/sudo check (expect root): /' || true

# home skeleton
RUN mkdir -p skel/.emacs.d && bash provision-corpus.sh skel/corpus
# COPY sources are paths in the project dir, not the image
COPY init.el skel/.emacs.d/init.el
COPY bashrc skel/.bashrc
COPY tmux.conf skel/.tmux.conf
RUN printf '[ -f ~/.bashrc ] && . ~/.bashrc\n' > skel/.bash_profile && \
    for u in alice bob; do \
        install -o "$u" -g "$u" -m 644 skel/.bashrc "/home/$u/.bashrc" && \
        install -o "$u" -g "$u" -m 644 skel/.bash_profile "/home/$u/.bash_profile"; \
    done
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
