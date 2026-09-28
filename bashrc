[[ $- != *i* ]] && return
command -v blesh-share >/dev/null && source -- "$(blesh-share)/ble.sh" --attach=none

alias vim="nvim"
alias ls="ls --color=auto"
alias ll="ls -lh --color=auto"
alias la="ls -lAh --color=auto"
alias grep="grep --color=auto"
alias diff="diff --color=auto"
eval "$(dircolors -b)"
export LESS="-R"
export GCC_COLORS="error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01"

HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend checkwinsize

command -v fzf >/dev/null && eval "$(fzf --bash)"
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
command -v bat >/dev/null && export MANPAGER="sh -c 'col -bx | bat -l man -p'"

for f in /nix/var/nix/profiles/nixlab/share/bash-completion/bash_completion \
         /nix/var/nix/profiles/nixlab/etc/profile.d/bash_completion.sh; do
    [[ -r $f ]] && . "$f" && break
done

__nixlab_prompt() {
    local status=$?
    local blue='\[\e[38;5;33m\]' purple='\[\e[38;2;189;147;249m\]' white='\[\e[37m\]'
    local cyan='\[\e[36m\]' yellow='\[\e[38;5;11m\]' magenta='\[\e[35m\]' red='\[\e[31m\]'
    local reset='\[\e[0m\]'
    local dir=${PWD##*/}
    [[ -z $dir ]] && dir=/
    local mark="${magenta}λ${reset}"
    (( status != 0 )) && mark="${red}ψ${reset}"
    PS1="${blue}\n┌──  ${reset}${purple}\u${white} ॐ  ${reset}${cyan}${dir//\\/\\\\}${reset}${blue}  ∞  ${reset}${yellow}\A${reset}${blue}  ࿔${reset}\n${blue}└─${reset} ${magenta} ${mark} "
}
PROMPT_COMMAND=__nixlab_prompt
[[ ${BLE_VERSION-} ]] && ble-attach
