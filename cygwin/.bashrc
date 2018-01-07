export DISPLAY=:0
export nodosfilewarning='' # disable CYGWIN warnings about DOS paths
export JAVA_HOME='C:/Program Files/Java/JDK1.8.0/jre'
export JDK_HOME='C:/Program Files/Java/JDK1.8.0'
GRAILS_VER=1.3.7
export GRAILS_HOME=c:/Users/Admin/grails-$GRAILS_VER
export ANT_HOME_PATH=/cygdrive/c/Users/Arnon/Downloads/development/apache/ant/apache-ant-1.9.2-bin/apache-ant-1.9.2
export ANT_HOME=C:/Users/Arnon/Downloads/development/apache/ant/apache-ant-1.9.2-bin/apache-ant-1.9.2
export GRADLE_HOME=C:/Users/arnon_000/Downloads/Media/development/gradle/2.1/gradle-2.1-all/gradle-2.1
export GRADLE_HOME_PATH=/cygdrive/c/Users/arnon_000/Downloads/Media/development/gradle/2.1/gradle-2.1-all/gradle-2.1

export PATH=/cygdrive/c/Program\ Files/Java/jdk1.8.0/bin:~/cygwin_bin:${ANT_HOME_PATH}/bin:/cygdrive/c/Users/Admin/griffon-0.3/bin:/cygdrive/c/Users/Admin/grails-$GRAILS_VER/bin:~/cygwin_bin/maven3/bin:${PATH}:/cygdrive/c/Program\ Files\ \(x86\)/Groovy/Groovy-2.3.2/bin:${GRADLE_HOME_PATH}/bin

# GPG support
export PATH=${PATH}:/cygdrive/c/Program\ Files\ \(x86\)/GNU/GnuPG

function parse_git_branch {
  #ref=$(git-symbolic-ref HEAD 2> /dev/null) || return
  ref=$(git branch --no-color 2> /dev/null |grep '^\*'|sed -e 's/^\* //')
  echo "("${ref#refs/heads/}")"
}

# original PS1: \[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$
export PS1="\[\e[33m\]\w\[\e]0;\w\a\] \[\e[32m\]\$(parse_git_branch)\[\e[0m\]\n\$"

alias ll='ls --color -lF'
alias lh='ls --color -lFh'
alias ls='ls --color'
alias la='ls --color -a'
alias winmerge=WinMergeU
# '/cygdrive/c/Program\ Files/SourceGear/Common/DiffMerge/sgdm.exe'
alias diffmerge='/cygdrive/c/Program\ Files/SourceGear/Common/DiffMerge/sgdm.exe'
alias diffx=diffmerge
alias windiff=diffmerge
alias emacs=~/emacs-24.2/bin/emacs.exe
alias mkdirs='mkdir -p'
# The following requires ncurses
alias c clear

. envs/3.6.1/bin/activate

#THIS MUST BE AT THE END OF THE FILE FOR GVM TO WORK!!!
[[ -s "/home/arnon_000/.gvm/bin/gvm-init.sh" ]] && source "/home/arnon_000/.gvm/bin/gvm-init.sh"
