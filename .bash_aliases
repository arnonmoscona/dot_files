alias ll='ls -G -lF' # mac does not accept --color
alias lh='ls -G -lFh'
alias ls='ls -G'
alias la='ls -G -a'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias mkdir='mkdir -pv'
alias h='history'
alias df="df -Tha --total"
alias du="du -ach | sort -h"
alias psg="ps aux | grep -v grep | grep -i -e VSZ -e"
alias mkdirs="mkdir -p"
alias c=clear

# Python stuff
alias ip=ipython
alias python3=". ~/envs/python3/bin/activate"
alias p3=python3
alias sandbox=". ~/envs/sandbox/bin/activate"

# Udemy stuff
alias w="cd ~/projects/website-django"
alias runserver="w;python manage.py runserver --settings=udemy.settings.local 0.0.0.0:8000"
alias rs=runserver
alias webpack="w;python manage.py webpackdevserver --settings=udemy.settings.local"
alias wp=webpack
alias bfe="w;python manage.py buildfrontend --settings=udemy.settings.local"
alias shell_plus="w;python manage.py shell_plus"
alias sp=shell_plus
alias rd="udemy-release-django"
alias unit="python manage.py test --settings=udemy.settings.test_unit udemy/discount udemy/rules" 
alias int="python manage.py test --settings=udemy.settings.test_integration udemy/discount udemy/rules" 

