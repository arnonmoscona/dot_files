alias ll='ls -G -lF' # mac does not accept --color
alias lh='ls -G -lFh'
alias ls='ls -G'
alias la='ls -G -a'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias mkdir='mkdir -pv'
alias df="df -Tha --total"
alias du="du -ach | sort -h"
alias psg="ps aux | grep -v grep | grep -i -e VSZ -e"
alias mkdirs="mkdir -p"
alias c=clear
alias md5sum='md5 -r'

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
alias release="ssh infra101 -t 'screen -D -R release'"
alias monitor="ssh agg -t 'screen -D -R monitor'"
# a good ommand line there is:
# udemy-logs-error-django   | grep -v 'SSL' | grep -v 'experiment' | grep -v 'read only' | grep -v 'merge' | grep -v 'spans' | grep -v 'Kafka'  | grep -v 'logo.jpg' | grep -v 'get_hls_root_playlist_url' | grep -v 'tier' | sed 's/\\n/\n/g'

_KEEPDB_="--keepdb"
# _KEEPDB_=""
_TEST_BASE="w; python manage.py test --settings=udemy.settings."
_TEST_UNIT="${_TEST_BASE}test_unit"
_TEST_INT_NO_KEEPDB_="${_TEST_BASE}test_integration ${_KEEPDB_}"
_TEST_INT="${_TEST_INT_NO_KEEPDB_} ${_KEEPDB_}"
_TEST_SCOPE_DISCOUNT="udemy/discount udemy/discount udemy/rules udemy/visit"

alias unit="${_TEST_UNIT} ${_TEST_SCOPE_DISCOUNT}"
alias unit_all="${_TEST_UNIT} udemy"
alias unit-all=unit_all

alias int="${_TEST_INT} ${_TEST_SCOPE_DISCOUNT}"
alias int_all="${_TEST_INT} udemy"
alias int-all=int_all
alias int-only="${_TEST_INT}"
alias int-only-no-keepdb="${_TEST_INT_NO_KEEPDB_}"

alias unit-js="w; cd static; ./node_modules/.bin/grunt test-with-sourcemaps"

alias co-master='git stash; git rev-parse --abbrev-ref HEAD > ~/.git-last-branch;  git co master'
alias co-last='git co `cat ~/.git-last-branch`; git stash pop'
alias co-back=co-last
alias morning='. ~/.bash_aliases; w; co-master ;git pull; pip install -r requirements/dev.txt; co-back; echo "REMEMBER to ssh dev, and you might need to build front end\n"'
alias gpf='git push -f orgin HEAD'
alias br='git branch'
alias rebase='git stash; git rebase master; git stash pop'

# The following vary between bash and zsh
if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
	alias h='history 0'
else
	alias ..='cd ..'
	alias ...='cd ../..'
	alias h='history'
fi

# psql
alias adw='ssh -fNL 5434:10.20.137.111:5432 arnonm@balboa.syapse.com; psql -d syadw -h localhost -U postgres -p 5434'
alias syadw=adw

