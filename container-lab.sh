#!/usr/bin/env bash
# container-lab.sh
#
#   ./container-lab.sh build              build/refresh the image (once)
#   ./container-lab.sh new  NAME          create + enter a fresh lab
#   ./container-lab.sh enter NAME         shell into a running lab
#   ./container-lab.sh attach NAME        enter a lab's tmux session (creates it)
#   ./container-lab.sh stop NAME          stop (keeps the volume)
#   ./container-lab.sh start NAME         start it again
#   ./container-lab.sh ls                 list labs
#   ./container-lab.sh rm NAME            remove lab + its volume
#   ./container-lab.sh teardown           remove ALL labs (and the image)
#
# Tunables (env):
#   NIXLAB_IMAGE      image tag                    (default nixlab:latest)
#   NIXLAB_CPUS       vCPUs per lab VM             (default 4)
#   NIXLAB_MEM        memory per lab VM            (default 4G)
#   NIXLAB_BUILD_MEM  memory for the image builder (default 4G)
#   NIXLAB_DNS        DNS server for builder + labs (default 1.1.1.1;
#                     set to "" to use container's default resolver)
set -euo pipefail

IMAGE="${NIXLAB_IMAGE:-nixlab:latest}"
CPUS="${NIXLAB_CPUS:-4}"
MEM="${NIXLAB_MEM:-4G}"
BUILD_MEM="${NIXLAB_BUILD_MEM:-4G}"
DNS="${NIXLAB_DNS-1.1.1.1}"
dns_args=()
[ -n "$DNS" ] && dns_args=(--dns "$DNS")
PREFIX="nixlab"
here="$(cd "$(dirname "$0")" && pwd)"

name() { echo "${PREFIX}-$1"; }
labs() { container ls -aq 2>/dev/null | grep "^${PREFIX}-" || true; }
exists() { labs | grep -qx "$(name "$1")"; }
running() { container ls -q 2>/dev/null | grep -qx "$(name "$1")"; }
shell() {
    local n=$1
    shift
    [ $# -gt 0 ] || set -- bash -l
    container exec -it -e HOME=/root -e TERM=xterm-256color -e COLORTERM=truecolor -e LANG=C.UTF-8 -w /root \
        "$(name "$n")" "$@"
}
need() {
    exists "$1" || {
        echo "no lab '$1' — create it with: $0 new $1" >&2
        exit 1
    }
}

container system status >/dev/null 2>&1 || container system start >/dev/null

case "${1:-}" in
build)
    container builder delete -f >/dev/null 2>&1 || true
    container builder start -m "$BUILD_MEM" ${dns_args[@]+"${dns_args[@]}"} >/dev/null
    container build -m "$BUILD_MEM" ${dns_args[@]+"${dns_args[@]}"} -t "$IMAGE" "$here"
    [ -e "$here/flake.lock" ] || container run --rm --entrypoint cat "$IMAGE" /opt/nixlab/flake.lock > "$here/flake.lock"
    echo "built $IMAGE"
    ;;

new)
    n="${2:?usage: new NAME}"
    c="$(name "$n")"
    exists "$n" && {
        echo "$c already exists — use enter/start"
        exit 1
    }
    container run -d --name "$c" -c "$CPUS" -m "$MEM" --cap-add SYS_PTRACE ${dns_args[@]+"${dns_args[@]}"} \
        -v "${c}-home:/root" "$IMAGE" sleep infinity >/dev/null
    echo "created $c"
    shell "$n"
    ;;

enter)
    n="${2:?usage: enter NAME}"
    need "$n"
    running "$n" || container start "$(name "$n")" >/dev/null
    shell "$n"
    ;;

attach)
    n="${2:?usage: attach NAME}"
    need "$n"
    running "$n" || container start "$(name "$n")" >/dev/null
    shell "$n" tmux new-session -A -s main
    ;;

stop)
    n="${2:?usage: stop NAME}"
    need "$n"
    container stop "$(name "$n")" >/dev/null
    echo "stopped"
    ;;

start)
    n="${2:?usage: start NAME}"
    need "$n"
    running "$n" || container start "$(name "$n")" >/dev/null
    echo "started"
    shell "$n"
    ;;

ls)
    container ls -a | awk -v p="^${PREFIX}-" 'NR==1 || $1 ~ p'
    ;;

rm)
    n="${2:?usage: rm NAME}"
    c="$(name "$n")"
    container delete -f "$c" >/dev/null 2>&1 || true
    container volume delete "${c}-home" >/dev/null 2>&1 || true
    echo "removed $c and its volume"
    ;;

teardown)
    ids="$(labs)"
    [ -n "$ids" ] && container delete -f $ids >/dev/null || true
    vols="$(container volume ls -q 2>/dev/null | grep "^${PREFIX}-" || true)"
    [ -n "$vols" ] && container volume delete $vols >/dev/null || true
    container image delete -f "$IMAGE" >/dev/null 2>&1 || true
    echo "all $PREFIX labs, volumes, and the image removed"
    ;;
*)
    echo "usage: $0 {build|new NAME|enter NAME|attach NAME|stop NAME|start NAME|ls|rm NAME|teardown}"
    exit 1
    ;;
esac
