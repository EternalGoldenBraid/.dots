# MSI laptop installation

## Status:
- Base installation works.

## Internet
`systemctl enable NetworkManager`
`systemctl start NetworkManager`
`nmtui`

### Things to add

- tmux config
  - tmux source ~/.config/tmux.conf

## AUR (Paru) packages
paru -S gnome-keyring eduvpn 1password ssh setups slack-desktop auto-cpufreq teams-for-linux \
        rofi-greenclip
    
- sudo auto-cpufreq --install

## On ssh configs and configs setup with 1password:

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

# On NVIDIA 

## See 1.1.2 Using udev rules to disable nvidia card

1. Check that nvidia card shows up in `lscpi`


2. Blacklist the nouveau drivers by creating
```bash
sudo vim /etc/modprobe.d/blacklist-nouveau.conf
```
```bash
blacklist nouveau
options nouveau modeset=0
```

3. Create udev rules in
```bash
sudo vim /etc/udev/rules.d/00-remove-nvidia.rules
```
```bash
# Remove NVIDIA USB xHCI Host Controller devices, if present
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"

# Remove NVIDIA USB Type-C UCSI devices, if present
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"

# Remove NVIDIA Audio devices, if present
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"

# Remove NVIDIA VGA/3D controller devices
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
```

4. Reboot and check that the nvidia card is not showing up in `lspci`
