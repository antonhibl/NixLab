#!/bin/sh
skel=/opt/nixlab/skel
if [ -d "$skel" ]; then
    cp -a --update=none "$skel/." /root/ 2>/dev/null || cp -an "$skel/." /root/
fi
bash /opt/nixlab/workbook-setup.sh || true
exec "$@"
