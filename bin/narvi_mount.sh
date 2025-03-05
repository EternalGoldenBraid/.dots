#!/bin/bash

mlflow_dir=narvi

### Mount lustre
host_user="qpnifi" # The user on the remote host
ssh_config_host="narvi_no_proxy" # A ssh config entry
remote_path="/lustre/scratch/qpnifi"
local_path="${PWD}/${mlflow_dir}"
# proxy_addrs="some_proxy_addrs" # E.g. tuni-proxy
# ssh_command="ssh -o ProxyJump=${host_user}@${proxy_addrs}"

# debug options
# sshfs_options="-o reconnect,debug,sshfs_debug -o ServerAliveInterval=15 -o ssh_command=$ssh_command"
#
# standard options
mkdir -p ${local_path}
# sshfs_options="-o reconnect -o ServerAliveInterval=15 -o ssh_command=$ssh_command"
sshfs_options="-o reconnect -o ServerAliveInterval=15"
sshfs \
    ${sshfs_options} \
    ${host_user}@${ssh_config_host}:${remote_path} \
    ${local_path}

printf "Mounted ${remote_path} to ${local_path}\n"

# function cleanup {
#     umount ${local_path}
#     rmdir ${local_path}
# }
#
# trap cleanup EXIT
