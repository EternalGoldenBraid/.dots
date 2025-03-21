# Useful commands

## Copy over ssh
scp username@remoteHost:/remote/dir/file.txt /local/dir/

## Journalctl

### Alert level logs from last boot
journalctl -b -p 1

## Zip

### Exclude files (note the single quotes to avoid shell expansion of the wildcard)
zip -r E2_Nicklas_Fianda_H296255.zip ex2 -x 'ex2/answers*'
