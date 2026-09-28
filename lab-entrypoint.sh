#!/bin/sh
mkdir -p /run
rm -f /run/nixlab-ready
skel=/opt/nixlab/skel
if [ -d "$skel" ]; then
    cp -a --update=none "$skel/." /root/ 2>/dev/null || cp -an "$skel/." /root/
fi
[ -e /etc/ssh/ssh_host_ed25519_key ] || ssh-keygen -q -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key
"$(command -v sshd)" -f /etc/ssh/sshd_config 2>/dev/null || true
bash /opt/nixlab/workbook-setup.sh || true
touch /run/nixlab-ready
exec "$@"
