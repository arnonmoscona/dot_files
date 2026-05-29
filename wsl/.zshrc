#export ZSH_DISABLE_COMPFIX=true  # on Tom's machine I cannot change the permissions properly:w

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
[ -d "/home/arnon/.oh-my-zsh" ] && export ZSH="/home/arnon/.oh-my-zsh"
#[ -d "/home/arnonm/.oh-my-zsh" ] && export ZSH="/home/arnonm/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git aws dotenv fabric httpie pep8 pip pipenv poetry rsync nvm)

ZSH_DOTENV_PROMPT=false
source ~/.oh-my-zsh/oh-my-zsh.sh
ZSH_DOTENV_PROMPT=true 

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
test -e "${HOME}/.bash_profile" && source "${HOME}/.bash_profile"
#test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
test -e "${HOME}/.zshrc_finalization" && source "${HOME}/.zshrc_finalization"


export PATH="$HOME/.poetry/bin:$PATH"

# Homebrew for WSL — must come before the brew-dependent fpath/compinit block
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

# fpath must be fully populated before compinit is called
fpath+=(~/.zfunc)
if type brew &>/dev/null; then
  fpath=($(brew --prefix)/share/zsh-completions $fpath)
fi
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select

# Intellij IDEA command line launcher
#if [ -d /Applications/IntelliJ\ IDEA.app/Contents/MacOS ]; then
#        export PATH=${PATH}:/Applications/IntelliJ\ IDEA.app/Contents/MacOS
#fi


# bun
#export BUN_INSTALL="$HOME/Library/Application Support/reflex/bun"
#export PATH="$BUN_INSTALL/bin:$PATH"

# NVM, node.js
#export NVM_DIR="$HOME/.nvm"
#  [ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
#  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
# Claude code
export PATH="${PATH}:$HOME/.nvm/versions/node/v24.8.0/bin"

# Node and npm
export PATH="${PATH}:$HOME/.nvm/versions/node/v24.8.0/bin/"

# nvm (for node)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
# The following only works in bash. Instead I added the nvm zsh plugin to the plugin list
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion


# Added by Antigravity
#export PATH="/home/arnon/.antigravity/antigravity/bin:$PATH"


# Added by Antigravity
#export PATH="/Users/arnon/.antigravity/antigravity/bin:$PATH"

# Rentec Direct

# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "/home/arnon/.bun/_bun" ] && source "/home/arnon/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# run ssh agent
eval `ssh-agent -s`
ssh-add ~/.ssh/id_rsa

# enable shopt (it is a bash builtin, and not on by default in zsh, which uses setopt instead)
# setopt AUTO_CD


if [ -f ~/.env ]; then
  source ~/.env
fi

