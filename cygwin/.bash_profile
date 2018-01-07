#!/bin/sh
export PATH=${PATH}:~/cygwin_bin


#------------------------------------------------------
# Add support for ssh-agent to prevent re-prompting
# for ssh passphrase

SSHAGENT=/usr/bin/ssh-agent
SSHAGENTARGS="-s"
if [ -z "$SSH_AUTH_SOCK" -a -x "$SSHAGENT" ]; then
	eval `$SSHAGENT $SSHAGENTARGS`
	trap "kill $SSH_AGENT_PID" 0
fi

echo 'Initialize ssh-agent'
ssh-add ~/.ssh/id_rsa

#------------------------------------------------------


# Shell Options
#
# See man bash for more options...
#
# Don't wait for job termination notification
# set -o notify
#
# Don't use ^D to exit
# set -o ignoreeof
#
# Use case-insensitive filename globbing
shopt -s nocaseglob
#
# Make bash append rather than overwrite the history on disk
shopt -s histappend
# Uncomment to turn on programmable completion enhancements.
# Any completions you add in ~/.bash_completion are sourced last.
[[ -f /etc/bash_completion ]] && . /etc/bash_completion
 
# Don't put duplicate lines in the history.
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
# Whenever displaying the prompt, write the previous line to disk
export PROMPT_COMMAND="history -a"
 
# Some people use a different file for aliases
if [ -f "${HOME}/.bash_aliases" ]; then
  source "${HOME}/.bash_aliases"
fi
 
alias ls='ls -hF --color=tty'
 
# Functions
#
# Some people use a different file for functions
if [ -f "${HOME}/.bash_functions" ]; then
  source "${HOME}/.bash_functions"
fi
#
# Some example functions:
#
# a) function settitle
# settitle ()
# {
#   echo -ne "\e]2;$@\a\e]1;$@\a";
# }
#

. ~/envs/3.6.1/bin/activate
. /cygdrive/c/Users/arnon_000/home/arnon_000/.bashrc

#THIS MUST BE AT THE END OF THE FILE FOR GVM TO WORK!!!
[[ -s "/home/arnon_000/.gvm/bin/gvm-init.sh" ]] && source "/home/arnon_000/.gvm/bin/gvm-init.sh"
