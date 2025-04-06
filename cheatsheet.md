# Useful commands

## Copy over ssh
scp username@remoteHost:/remote/dir/file.txt /local/dir/

## Journalctl

### Alert level logs from last boot
journalctl -b -p 1

### Check for systemd service things:
```
journalctl --user-unit=syncthing | grep config
```

## Zip

### Exclude files (note the single quotes to avoid shell expansion of the wildcard)
zip -r E2_Nicklas_Fianda_H296255.zip ex2 -x 'ex2/answers*'

# Syncthing

## Setup
```
sudo pacman -Sy syncthing
systemctl --user enable syncthing
systemctl --user start syncthing
```
Lingering: https://wiki.archlinux.org/title/Systemd/User
```
loginctl enable-linger $(whoami)
```

```
 export SYNCTHING_API_KEY=your_api_key
```

# Aliases 

To run the command without alias
```
\<the_command>
```

To check the alias
```
type <alias_name>
```

To unset the alias
```
unalias <alias_name>
```
