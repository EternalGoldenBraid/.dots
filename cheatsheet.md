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

## Background processes

https://stackoverflow.com/questions/44222883/run-a-shell-script-and-immediately-background-it-however-keep-the-ability-to-in

Add & to the end of the command to run it in the background. For example:
```
> zathura instructions/E4_instructions.pdf &
```

Inspect jobs with:
```
 > jobs
[1]+  Running                 zathura instructions/E4_instructions.pdf &
```

Bring to foreground:
```
> fg 1
```

Put to sleep and resume to your shell:
```
ctrl + z
```

Resume:
```
> bg 1
```
