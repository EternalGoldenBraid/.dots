# MSI laptop installation

## Things to add

- tmux config
  - tmux source ~/.config/tmux.conf

paru -S gnome-keyring eduvpn 1password ssh setups slack-desktop auto-cpufreq teams-for-linux

- sudo auto-cpufreq --install


# On ssh configs and configs setup with 1password:

- export the github key from 1password and store in some `temp_gh_key`
- `ssh-add temp_gh_key`
- Pull .dots
- pull privete ssh configs (requires the above key) `git submodule update --init --recursive`
- remove old .ssh dir: `rm -r ~/.ssh`
- link the .ssh dir: `ln -sf ~/.dotfiles/.ssh ~/.ssh`
- Create a main config at: `~/.ssh/config` containing:
```
Include ~/.ssh/.ssh_configs/1password_config
```
- Test ssh-agent acess to 1password keys with: `ssh -T git@github.com`. Should prompt for password.


At this points you should have a acess to 1password ssh keys.
Include any of the configs in .ssh/private_configs to get **stuff** done.

