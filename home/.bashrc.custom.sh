# Directories =========================================================================================================
[[ -d "$HOME/Pictures" ]]   || mkdir -p $HOME/Pictures
[[ -d "$HOME/Videos" ]]     || mkdir -p $HOME/Videos
[[ -d "$HOME/Downloads" ]]  || mkdir -p $HOME/Downloads
[[ -d "$HOME/Documents" ]]       || mkdir -p $HOME/Docs
[[ -d "$HOME/.local/bin" ]] || mkdir -p $HOME/.local/bin
[[ -d "$HOME/.local/opt" ]] || mkdir -p $HOME/.local/opt

# Environemnt =========================================================================================================
export PATH=$PATH:/home/$(whoami)/.local/bin
export EDITOR=nvim

# Alias ===============================================================================================================
alias ls='ls -h --color=auto'

alias vim=nvim
alias v=vim

# Shell ===============================================================================================================
CRESET="\[\033[0m\]";
CGREEN="\[\033[1;32m\]";
CYELLOW="\[\033[1;33m\]";
CSGREEN="\[\033[0;32m\]";

function _ps1_get_git_branch() {
  BRANCH=$(git branch --show-current 2>/dev/null)
  [[ -z $BRANCH ]] || echo " @ $BRANCH"
}

function _ps1_git_has_changes() {
  STATUS=$(git status --short 2> /dev/null)
  [[ -z $STATUS ]] || echo " ✗ "
}

PROMPT_COMMAND='PS1_GIT=$(_ps1_get_git_branch);PS1_GIT_STATUS=$(_ps1_git_has_changes)';
PS1="\n$CGREEN\W$CRESET$CYELLOW\${PS1_GIT}\${PS1_GIT_STATUS}$CSGREEN \\$ $CRESET";


eval "$(mise activate bash)"
