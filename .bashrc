#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

source ~/.screenlayout/layout.sh

if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi

# Colors
GREEN="\[$(tput setaf 2)\]"
RESET="\[$(tput sgr0)\]"

PS1="${GREEN} \h:\u \w ${RESET}> "

source ~/.exports

#export PATH="$HOME/.local/bin:$PATH"
export PATH=$PATH:~/bin

### Pip
export PIP_REQUIRE_VIRTUALENV='true'

# pudb breakpoint()
export PYTHONBREAKPOINT="pudb.set_trace"

# ssh
if [ -z "$SSH_AUTH_SOCK" ] ; then
    eval `ssh-agent`
    ssh-add
fi


# BEGIN_KITTY_SHELL_INTEGRATION
if test -n "$KITTY_INSTALLATION_DIR" -a -e "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"; then source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"; fi
# END_KITTY_SHELL_INTEGRATION
export DEFAULT_TERM=kitty

export MANPAGER='nvim +Man!'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/nicklas/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/nicklas/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/nicklas/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/nicklas/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

eval "$(zoxide init bash)"
