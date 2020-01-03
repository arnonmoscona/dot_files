alias ls='ls -hF --color=tty'
alias la='ls -a'
alias ll='ls -la'
alias c=clear
alias vi=vim
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias mkdir='mkdir -pv'
alias h='history'
alias df="df -Tha --total"
alias du="du -ach | sort -h"
alias psg="ps aux | grep -v grep | grep -i -e VSZ -e"


# The following vary between bash and zsh
if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
	alias h='history 0'
else
	alias ..='cd ..'
	alias ...='cd ../..'
	alias h='history'
fi

