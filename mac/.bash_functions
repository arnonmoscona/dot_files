cd_func ()
{
  local x2 the_new_dir adir index
  local -i cnt

  if [[ $1 ==  "--" ]]; then
    dirs -v
    return 0
  fi

  the_new_dir=$1
  [[ -z $1 ]] && the_new_dir=$HOME

  if [[ ${the_new_dir:0:1} == '-' ]]; then
    #
    # Extract dir N from dirs
    index=${the_new_dir:1}
    [[ -z $index ]] && index=1
    adir=$(dirs +$index)
    [[ -z $adir ]] && return 1
    the_new_dir=$adir
  fi

  #
  # '~' has to be substituted by ${HOME}
  [[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"

  #
  # Now change to the new dir and add to the top of the stack
  pushd "${the_new_dir}" > /dev/null
  [[ $? -ne 0 ]] && return 1
  the_new_dir=$(pwd)

#
  # Trim down everything beyond 11th entry
  popd -n +11 2>/dev/null 1>/dev/null
  #
  # Remove any other occurence of this dir, skipping the top of the stack
  for ((cnt=1; cnt <= 10; cnt++)); do
    x2=$(dirs +${cnt} 2>/dev/null)
    [[ $? -ne 0 ]] && return 0
    [[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
    if [[ "${x2}" == "${the_new_dir}" ]]; then
      popd -n +$cnt 2>/dev/null 1>/dev/null
      cnt=cnt-1
    fi
  done

  return 0
}

alias cd=cd_func

#========================================================================

if [ -f $(brew --prefix)/share/bash-completion/bash_completion ]; then
  . $(brew --prefix)/share/bash-completion/bash_completion
fi

brewPkg() {
  pkg=$1
  shift
  (
    brew install ${pkg} $*  2>&1 |
        tee $HOME/Library/Logs/Homebrew/$USER/${pkg}-$(date +"%F_%H%M").txt
  )
}

brewSrcPkg() {
  pkg=$1
  shift
  (
    brew install --build-from-source  ${pkg} $*  2>&1 |
        tee $HOME/Library/Logs/Homebrew/$USER/${pkg}-$(date +"%F_%H%M").txt
  )
}

brewSrcPkgWgcc() {
  pkg=$1
  shift
  (
    export CC=gcc-6
    export CXX=g++-6
    export HOMEBREW_CC=gcc-6
    export HOMEBREW_CXX=g++-6
    brew install --build-from-source  ${pkg} $*  2>&1 |
        tee $HOME/Library/Logs/Homebrew/$USER/${pkg}-$(date +"%F_%H%M").txt
  )
}


#========================================================================

mcd ()
{
    mkdir -p -- "$1";
    cd "$1";
}

# run a single test
function t { `echo $*  | sed -e 's/-//' | awk '{print $2"."$1}' | sed -e 's/[\(\)]//g' | sed -e 's/\(.*\)\.\(.*\..*\)/.\/manage.py test --settings=udemy.settings.test_integration --keepdb \1:\2/'`; }

function  parse_git_branch {
  #ref=$(git-symbolic-ref HEAD 2> /dev/null) || return
  ref=$(git branch --no-color 2> /dev/null |grep '^\*'|sed -e 's/^\* //')
  echo "("${ref#refs/heads/}")"
}

