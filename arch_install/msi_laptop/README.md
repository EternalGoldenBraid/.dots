# MSI laptop installation

## Things to add

- gnome-keyring
  - paru -Sy gnome-keyring libsecret seahorse

- eduvpn

- 1password ssh setups
  - paru -S 1password 1password-cli

- link all configs present in .dotfiles/.config

- tmux config
  - tmux source ~/.config/tmux.conf

- slac
  - paru -S slack


# On ssh configs and configs setup with 1password:

- export the github key from 1password and store in some `temp_gh_key`
- `ssh-add temp_gh_key`
- Pull .dots
- pull privete ssh configs (requires the above key) `git submodule update --init --recursive`
- remove old .ssh dir: `rm -r ~/.ssh`
- link the .ssh dir: `ln -sf ~/.dotfiles/.ssh ~/.ssh`

At this points you should have a acess to 1pass ssh keys.
Include any of the configs in .ssh/private_configs to get **stuff** done.

