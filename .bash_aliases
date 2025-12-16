# Source this file
alias vi=nvim
alias reload='source ~/.bashrc'
alias ls='ls --color=auto'
alias ls='exa'
# alias cd='z'
alias ..='cd ..;pwd'
alias ...='cd ../..;pwd'
alias ....='cd ../../..;pwd'
alias rm='rm -i'
alias home='cd $HOME'
alias pacinstall='sudo pacman -Syu'
alias dots='cd ~/.dotfiles'
alias bins='cd ~/.dotfiles/bin'
alias tree='exa --tree'

get_num_physical_cores() {
  grep '^core id' /proc/cpuinfo | sort -u | wc -l
}

ncdu() {
  command ncdu -t"$(get_num_physical_cores)" "$@"
}
alias diskspace='ncdu'


alias sammu='shutdown -h now'
alias sleep='sudo systemctl suspend'
alias gitsave='git add --all && git commit -m "unimportant" && git push'

# Temporary configurations
alias activate='pixi shell'
alias uva='source ./.venv/bin/activate'

# Tmux startups
alias daymux='~/.dotfiles/tmux/tmux_daily.sh'

# Uni
alias course='cd ~/Documents/Study/Bachelor_0/Semester_1/'
alias mage='g++ main.cpp -Wall -o main.exe'
alias study='cd ~/Study/Masters/'
alias tuni='ssh linux-ssh.tuni.fi -l $TUNIUSERNAME'

### Pip
export PIP_REQUIRE_VIRTUALENV='true'

# pudb breakpoint()
export PYTHONBREAKPOINT="pudb.set_trace"
alias dots='cd ~/.dotfiles'

# Daily
alias cdaily='cd ~/Projects/daily/daily'

# Laptop
alias valo='sudo vim /sys/class/backlight/intel_backlight/brightness'
alias d='redshift -PO 6500'
alias n='redshift -PO 4000'
alias nn='redshift -PO 2500'
alias netti='nmcli device wifi'
