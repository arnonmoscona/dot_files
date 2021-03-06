#!/usr/bin/bash
#echo ".bash_profile"

# Java --------------------------
# export JDK_NAME="JDK1.8.0_111"
# export JAVA_HOME="C:/Program Files/Java/${JDK_NAME}/jre"
# export JDK_HOME="C:/Program Files/Java/${JDK_NAME}"

# Shell -------------------------
# Shell Options..................
#
# See man bash for more options...
#
# Don't wait for job termination notification
# set -o notify
#
# Don't use ^D to exit
set -o ignoreeof
#
# Use case-insensitive filename globbing
if [ "$SHELL" = "/bin/bash" ]; then
	if [ -x "$(shopt 2>&1 > /dev/null)" ]; then
	  shopt -s nocaseglob
	fi
fi
#
# Make bash append rather than overwrite the history on disk
if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
  if [ -x "$(shopt 2>&1 > /dev/null)" ]; then
	setopt SHARE_HISTORY
	setopt APPEND_HISTORY
  fi
else
  if [ -x "$(shopt 2>&1 > /dev/null)" ]; then
	shopt -s histappend
  fi
fi
# Uncomment to turn on programmable completion enhancements.
# Any completions you add in ~/.bash_completion are sourced last.
[[ -f /etc/bash_completion ]] && . /etc/bash_completion

# Don't put duplicate lines in the history.
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups

# Whenever displaying the prompt, write the previous line to disk
export PROMPT_COMMAND="history -a"

export PATH=~/bin:${PATH}
export PATH=${PATH}:~/.local/bin:~/homebrew/bin

# Some people use a different file for aliases
if [ -f "${HOME}/.bash_aliases" ]; then
  source "${HOME}/.bash_aliases"
fi

# Some people use a different file for functions
if [ -f "${HOME}/.bash_functions" ]; then
  source "${HOME}/.bash_functions"
fi

# Git completions
if [ -f "{HOME}/git-completion.bash" ]; then
  source "{HOME}/git-completion.bash"
fi
# END shell options ..............

# prompt stuff
function parse_git_branch {
  #ref=$(git-symbolic-ref HEAD 2> /dev/null) || return
  ref=$(git branch --no-color 2> /dev/null |grep '^\*'|sed -e 's/^\* //')
  echo "("${ref#refs/heads/}")"
}

# original PS1: \[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$
# original Ubuntu PS1: \[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\u@\h:\w\$
# original mac PS1: \h:\W \u\$
export NEWLINE=$'\n'
if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
	:
	# Use .zshrc_finalization instead
	#setopt PROMPT_SUBST
	#export PROMPT="╭─ %F{green}%~ %F{yellow}$(parse_git_branch)%F{reset_color}
#╰─%B${user_symbol}%b "
else
	export PS1="\[\e[33m\]\w\[\e]0;\w\a\] \[\e[32m\]\$(parse_git_branch)\[\e[0m\]\n\$"
fi

# Python ------------------------
# pyenv
# Add pyenv executable to PATH and
# enable shims by adding the following
# to ~/.profile:
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
…
# Load pyenv into the shell by adding
# the following to ~/.bashrc:
eval "$(pyenv init -)"

eval "$(pyenv virtualenv-init -)"
#. ~/envs/python3/bin/activate
#export DJANGO_SETTINGS_MODULE=udemy.settings.local 
#export PATH=${PATH}:~/envs/python3/bin

# the following depends on openssl (brew install openssl) and is required for psycopg2
export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl/lib/
# The following two are here for pip install cryptography
export CPPFLAGS=-I/usr/local/opt/openssl/include
export LDFLAGS=-L/usr/local/opt/openssl/lib

# Add Yarn to path
export PATH="$HOME/.yarn/bin:${PATH}"

# Add mysql to the path
export PATH=${PATH}:/usr/local/opt/mysql@5.6/bin/

# add local node executables
export PATH=${PATH}:./node_modules/.bin/

# SSH ---------------------------
ssh-add -k ~/.ssh/id_rsa

# Docker stuff (Syapse)
export AWS_PROFILE=dev
# Some people use a different file for aliases
if [ -f "${HOME}/.bash_aws" ]; then
  source "${HOME}/.bash_aws"
fi
# add psql to path regardless of whether brew postresql is installed
#export PATH="/Users/arnonmoscona/homebrew/opt/libpq/bin:$PATH"

# The following must be at the end of the script for pyenv to work correctly
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi


if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
	# be sure to ln -s ~/.bash_profile ~/.zshrc
	source ~/.zshrc_finalization
	test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
else
	test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"
fi

export PATH="$HOME/.poetry/bin:$PATH"

# Rust support
source "$HOME/.cargo/env"

unset  PIP_USER



export PATH="$HOME/.yarn/bin:$PATH"

# .env
if [ -f "${HOME}/.env" ]; then
  echo "Detected .env: running it..."
  source "${HOME}/.env"
fi

