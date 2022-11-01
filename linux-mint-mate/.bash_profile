#!/usr/bin/bash -x
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
export PYTHONPYCACHEPREFIX="$HOME/tmp/pycache"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
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

# CLI visual enhancements
#export LS_COLORS=`vivid generate molokai`
export MOLOKAI_COLORS='fi=0:*~=0;38;2;122;112;112:mh=0:st=0:no=0:mi=0;38;2;0;0;0;48;2;255;74;68:ca=0:di=0;38;2;102;217;239:su=0:sg=0:cd=0;38;2;249;38;114;48;2;51;51;51:or=0;38;2;0;0;0;48;2;255;74;68:ex=1;38;2;249;38;114:ln=0;38;2;249;38;114:bd=0;38;2;102;217;239;48;2;51;51;51:do=0;38;2;0;0;0;48;2;249;38;114:tw=0:ow=0:rs=0:so=0;38;2;0;0;0;48;2;249;38;114:pi=0;38;2;0;0;0;48;2;102;217;239:*.h=0;38;2;0;255;135:*.a=1;38;2;249;38;114:*.t=0;38;2;0;255;135:*.m=0;38;2;0;255;135:*.c=0;38;2;0;255;135:*.o=0;38;2;122;112;112:*.z=4;38;2;249;38;114:*.r=0;38;2;0;255;135:*.d=0;38;2;0;255;135:*.p=0;38;2;0;255;135:*.el=0;38;2;0;255;135:*.pm=0;38;2;0;255;135:*.py=0;38;2;0;255;135:*.cr=0;38;2;0;255;135:*.cs=0;38;2;0;255;135:*.hs=0;38;2;0;255;135:*.gv=0;38;2;0;255;135:*.kt=0;38;2;0;255;135:*.cp=0;38;2;0;255;135:*.wv=0;38;2;253;151;31:*.fs=0;38;2;0;255;135:*.js=0;38;2;0;255;135:*.mn=0;38;2;0;255;135:*.7z=4;38;2;249;38;114:*.td=0;38;2;0;255;135:*.pl=0;38;2;0;255;135:*.xz=4;38;2;249;38;114:*.rm=0;38;2;253;151;31:*.go=0;38;2;0;255;135:*.pp=0;38;2;0;255;135:*.md=0;38;2;226;209;57:*.rs=0;38;2;0;255;135:*.vb=0;38;2;0;255;135:*.lo=0;38;2;122;112;112:*.as=0;38;2;0;255;135:*.bc=0;38;2;122;112;112:*.ui=0;38;2;166;226;46:*.gz=4;38;2;249;38;114:*.cc=0;38;2;0;255;135:*.ts=0;38;2;0;255;135:*.bz=4;38;2;249;38;114:*css=0;38;2;0;255;135:*.hh=0;38;2;0;255;135:*.di=0;38;2;0;255;135:*.ex=0;38;2;0;255;135:*.ll=0;38;2;0;255;135:*.sh=0;38;2;0;255;135:*.so=1;38;2;249;38;114:*.jl=0;38;2;0;255;135:*.hi=0;38;2;122;112;112:*.ko=1;38;2;249;38;114:*.rb=0;38;2;0;255;135:*.ps=0;38;2;230;219;116:*.nb=0;38;2;0;255;135:*.ml=0;38;2;0;255;135:*.la=0;38;2;122;112;112:*.m4v=0;38;2;253;151;31:*.fon=0;38;2;253;151;31:*.tmp=0;38;2;122;112;112:*.ico=0;38;2;253;151;31:*.clj=0;38;2;0;255;135:*.bbl=0;38;2;122;112;112:*.tif=0;38;2;253;151;31:*.flv=0;38;2;253;151;31:*.yml=0;38;2;166;226;46:*.ppm=0;38;2;253;151;31:*.aux=0;38;2;122;112;112:*.lua=0;38;2;0;255;135:*.tex=0;38;2;0;255;135:*.exe=1;38;2;249;38;114:*.arj=4;38;2;249;38;114:*.svg=0;38;2;253;151;31:*.png=0;38;2;253;151;31:*.kts=0;38;2;0;255;135:*.dox=0;38;2;166;226;46:*.dot=0;38;2;0;255;135:*.ods=0;38;2;230;219;116:*.bz2=4;38;2;249;38;114:*.ltx=0;38;2;0;255;135:*.sty=0;38;2;122;112;112:*.erl=0;38;2;0;255;135:*.elm=0;38;2;0;255;135:*.exs=0;38;2;0;255;135:*.img=4;38;2;249;38;114:*.gvy=0;38;2;0;255;135:*.pid=0;38;2;122;112;112:*.cxx=0;38;2;0;255;135:*.rar=4;38;2;249;38;114:*.pyd=0;38;2;122;112;112:*.pyo=0;38;2;122;112;112:*.ttf=0;38;2;253;151;31:*.git=0;38;2;122;112;112:*.ipp=0;38;2;0;255;135:*.odp=0;38;2;230;219;116:*.fsi=0;38;2;0;255;135:*.pkg=4;38;2;249;38;114:*.ind=0;38;2;122;112;112:*.sbt=0;38;2;0;255;135:*.blg=0;38;2;122;112;112:*.vob=0;38;2;253;151;31:*.aif=0;38;2;253;151;31:*.com=1;38;2;249;38;114:*.awk=0;38;2;0;255;135:*.kex=0;38;2;230;219;116:*.pas=0;38;2;0;255;135:*.bcf=0;38;2;122;112;112:*.pyc=0;38;2;122;112;112:*.mp4=0;38;2;253;151;31:*.bag=4;38;2;249;38;114:*.c++=0;38;2;0;255;135:*.fnt=0;38;2;253;151;31:*.wmv=0;38;2;253;151;31:*.otf=0;38;2;253;151;31:*.tbz=4;38;2;249;38;114:*.xmp=0;38;2;166;226;46:*.cfg=0;38;2;166;226;46:*.asa=0;38;2;0;255;135:*.xlr=0;38;2;230;219;116:*.pps=0;38;2;230;219;116:*.bmp=0;38;2;253;151;31:*.mli=0;38;2;0;255;135:*.ogg=0;38;2;253;151;31:*.wma=0;38;2;253;151;31:*.dll=1;38;2;249;38;114:*.cpp=0;38;2;0;255;135:*.def=0;38;2;0;255;135:*.ppt=0;38;2;230;219;116:*.pbm=0;38;2;253;151;31:*.htm=0;38;2;226;209;57:*TODO=1:*.mp3=0;38;2;253;151;31:*.m4a=0;38;2;253;151;31:*.zst=4;38;2;249;38;114:*.nix=0;38;2;166;226;46:*.inc=0;38;2;0;255;135:*.fls=0;38;2;122;112;112:*.hpp=0;38;2;0;255;135:*.vim=0;38;2;0;255;135:*.odt=0;38;2;230;219;116:*.iso=4;38;2;249;38;114:*.pod=0;38;2;0;255;135:*.rst=0;38;2;226;209;57:*.cgi=0;38;2;0;255;135:*.eps=0;38;2;253;151;31:*.sxw=0;38;2;230;219;116:*.fsx=0;38;2;0;255;135:*.tgz=4;38;2;249;38;114:*.pdf=0;38;2;230;219;116:*.psd=0;38;2;253;151;31:*.wav=0;38;2;253;151;31:*hgrc=0;38;2;166;226;46:*.bst=0;38;2;166;226;46:*.rpm=4;38;2;249;38;114:*.sql=0;38;2;0;255;135:*.tsx=0;38;2;0;255;135:*.xcf=0;38;2;253;151;31:*.dpr=0;38;2;0;255;135:*.log=0;38;2;122;112;112:*.vcd=4;38;2;249;38;114:*.txt=0;38;2;226;209;57:*.tar=4;38;2;249;38;114:*.pgm=0;38;2;253;151;31:*.csv=0;38;2;226;209;57:*.apk=4;38;2;249;38;114:*.ini=0;38;2;166;226;46:*.php=0;38;2;0;255;135:*.zsh=0;38;2;0;255;135:*.mkv=0;38;2;253;151;31:*.htc=0;38;2;0;255;135:*.hxx=0;38;2;0;255;135:*.idx=0;38;2;122;112;112:*.doc=0;38;2;230;219;116:*.tcl=0;38;2;0;255;135:*.ics=0;38;2;230;219;116:*.bib=0;38;2;166;226;46:*.xml=0;38;2;226;209;57:*.mir=0;38;2;0;255;135:*.gif=0;38;2;253;151;31:*.ilg=0;38;2;122;112;112:*.xls=0;38;2;230;219;116:*.sxi=0;38;2;230;219;116:*.bat=1;38;2;249;38;114:*.swp=0;38;2;122;112;112:*.epp=0;38;2;0;255;135:*.avi=0;38;2;253;151;31:*.tml=0;38;2;166;226;46:*.inl=0;38;2;0;255;135:*.jar=4;38;2;249;38;114:*.pro=0;38;2;166;226;46:*.zip=4;38;2;249;38;114:*.toc=0;38;2;122;112;112:*.dmg=4;38;2;249;38;114:*.mpg=0;38;2;253;151;31:*.bak=0;38;2;122;112;112:*.bin=4;38;2;249;38;114:*.ps1=0;38;2;0;255;135:*.deb=4;38;2;249;38;114:*.rtf=0;38;2;230;219;116:*.bsh=0;38;2;0;255;135:*.jpg=0;38;2;253;151;31:*.csx=0;38;2;0;255;135:*.swf=0;38;2;253;151;31:*.out=0;38;2;122;112;112:*.mov=0;38;2;253;151;31:*.mid=0;38;2;253;151;31:*.h++=0;38;2;0;255;135:*.h264=0;38;2;253;151;31:*.java=0;38;2;0;255;135:*.epub=0;38;2;230;219;116:*.tiff=0;38;2;253;151;31:*.fish=0;38;2;0;255;135:*.dart=0;38;2;0;255;135:*.mpeg=0;38;2;253;151;31:*.xlsx=0;38;2;230;219;116:*.docx=0;38;2;230;219;116:*.json=0;38;2;166;226;46:*.lisp=0;38;2;0;255;135:*.lock=0;38;2;122;112;112:*.jpeg=0;38;2;253;151;31:*.conf=0;38;2;166;226;46:*.rlib=0;38;2;122;112;112:*.html=0;38;2;226;209;57:*.bash=0;38;2;0;255;135:*.diff=0;38;2;0;255;135:*.opus=0;38;2;253;151;31:*.purs=0;38;2;0;255;135:*.psm1=0;38;2;0;255;135:*.orig=0;38;2;122;112;112:*.hgrc=0;38;2;166;226;46:*.tbz2=4;38;2;249;38;114:*.make=0;38;2;166;226;46:*.pptx=0;38;2;230;219;116:*.psd1=0;38;2;0;255;135:*.flac=0;38;2;253;151;31:*.toml=0;38;2;166;226;46:*.less=0;38;2;0;255;135:*.webm=0;38;2;253;151;31:*.yaml=0;38;2;166;226;46:*.shtml=0;38;2;226;209;57:*.cache=0;38;2;122;112;112:*.toast=4;38;2;249;38;114:*.scala=0;38;2;0;255;135:*.patch=0;38;2;0;255;135:*shadow=0;38;2;166;226;46:*.mdown=0;38;2;226;209;57:*.xhtml=0;38;2;226;209;57:*.cmake=0;38;2;166;226;46:*.dyn_o=0;38;2;122;112;112:*.ipynb=0;38;2;0;255;135:*README=0;38;2;0;0;0;48;2;230;219;116:*.cabal=0;38;2;0;255;135:*.class=0;38;2;122;112;112:*passwd=0;38;2;166;226;46:*.swift=0;38;2;0;255;135:*.config=0;38;2;166;226;46:*.gradle=0;38;2;0;255;135:*INSTALL=0;38;2;0;0;0;48;2;230;219;116:*.ignore=0;38;2;166;226;46:*TODO.md=1:*.groovy=0;38;2;0;255;135:*.flake8=0;38;2;166;226;46:*.matlab=0;38;2;0;255;135:*COPYING=0;38;2;182;182;182:*.dyn_hi=0;38;2;122;112;112:*LICENSE=0;38;2;182;182;182:*.desktop=0;38;2;166;226;46:*Doxyfile=0;38;2;166;226;46:*setup.py=0;38;2;166;226;46:*TODO.txt=1:*Makefile=0;38;2;166;226;46:*.gemspec=0;38;2;166;226;46:*.DS_Store=0;38;2;122;112;112:*.markdown=0;38;2;226;209;57:*configure=0;38;2;166;226;46:*.rgignore=0;38;2;166;226;46:*README.md=0;38;2;0;0;0;48;2;230;219;116:*.cmake.in=0;38;2;166;226;46:*COPYRIGHT=0;38;2;182;182;182:*.kdevelop=0;38;2;166;226;46:*.fdignore=0;38;2;166;226;46:*CODEOWNERS=0;38;2;166;226;46:*SConscript=0;38;2;166;226;46:*SConstruct=0;38;2;166;226;46:*.gitconfig=0;38;2;166;226;46:*Dockerfile=0;38;2;166;226;46:*.scons_opt=0;38;2;122;112;112:*.localized=0;38;2;122;112;112:*README.txt=0;38;2;0;0;0;48;2;230;219;116:*.gitignore=0;38;2;166;226;46:*INSTALL.md=0;38;2;0;0;0;48;2;230;219;116:*.synctex.gz=0;38;2;122;112;112:*.travis.yml=0;38;2;230;219;116:*.gitmodules=0;38;2;166;226;46:*LICENSE-MIT=0;38;2;182;182;182:*INSTALL.txt=0;38;2;0;0;0;48;2;230;219;116:*Makefile.in=0;38;2;122;112;112:*Makefile.am=0;38;2;166;226;46:*MANIFEST.in=0;38;2;166;226;46:*.fdb_latexmk=0;38;2;122;112;112:*CONTRIBUTORS=0;38;2;0;0;0;48;2;230;219;116:*configure.ac=0;38;2;166;226;46:*appveyor.yml=0;38;2;230;219;116:*.applescript=0;38;2;0;255;135:*.clang-format=0;38;2;166;226;46:*.gitattributes=0;38;2;166;226;46:*CMakeLists.txt=0;38;2;166;226;46:*LICENSE-APACHE=0;38;2;182;182;182:*CMakeCache.txt=0;38;2;122;112;112:*CONTRIBUTORS.md=0;38;2;0;0;0;48;2;230;219;116:*requirements.txt=0;38;2;166;226;46:*.sconsign.dblite=0;38;2;122;112;112:*CONTRIBUTORS.txt=0;38;2;0;0;0;48;2;230;219;116:*package-lock.json=0;38;2;122;112;112:*.CFUserTextEncoding=0;38;2;122;112;112'
export LS_COLORS=${MOLOKAI_COLORS}


# SSH ---------------------------
#ssh-add -k ~/.ssh/id_rsa


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
#source "$HOME/.cargo/env"

unset  PIP_USER

export PATH="$HOME/.yarn/bin:$PATH"

# .env
if [ -f "${HOME}/.env" ]; then
  echo "Detected .env: running it..."
  source "${HOME}/.env"
fi

eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
