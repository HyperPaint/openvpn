#!/bin/bash

source "/root/scripts/hbdl/log.sh"

you_need_run_container_in_privileged_mode="You need run container in privileged mode"

if [[ -d "/dev/net" ]]; then
  log "/dev/net found"
else
  mkdir "/dev/net" || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
  log "/dev/net created"
fi

if [[ -c "/dev/net/tun" ]]; then
  log "/dev/net/tun found"
else
  mknod /dev/net/tun c 10 200 || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
  log "/dev/net/tun created"
fi
