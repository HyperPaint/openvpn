#!/bin/bash

source "/root/scripts/.env"

source "/root/scripts/hbdl/log.sh"

you_need_run_container_in_privileged_mode="You need to run container in privileged mode"

log "Drop all traffic"
iptables --verbose --policy INPUT DROP || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
iptables --verbose --policy FORWARD DROP || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
iptables --verbose --policy OUTPUT DROP || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
iptables --verbose --flush || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
iptables --verbose --table nat --flush || { error "$you_need_run_container_in_privileged_mode"; exit 1; }

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

if [[ "$NAT_ENABLED" == 1 ]]; then
  # shellcheck disable=SC2206
  array=(${NAT//,/ })

  if [[ "$(sysctl -n net.ipv4.ip_forward)" -eq 0 ]]; then
    sysctl net.ipv4.ip_forward=1 || { error "You need to run 'sysctl net.ipv4.ip_forward=1' on host system";  exit 1; }
  fi

  for item in "${array[@]}"; do
    log "NAT $item"
    iptables --verbose --table nat --append POSTROUTING --source "$item" --jump MASQUERADE || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
  done
fi

if [[ "$WHITELIST_ENABLED" == 1 ]]; then
  if [[ "$BLACKLIST_ENABLED" == 1 ]]; then
    error "Whitelist and blacklist enabled simultaneously"
    exit 1
  fi

  iptables --verbose --policy FORWARD DROP || { error "$you_need_run_container_in_privileged_mode"; exit 1; }

  # shellcheck disable=SC2207
  array=($(echo "$WHITELIST" | sed 's/ /;/g' | sed 's/,/ /g'))
  regex="^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/([0-9\*]+);([0-9\*]+)/([A-Za-z\*]+)$"

  for item in "${array[@]}"; do
    log "Whitelist ${item//;/ }"

    address="$(echo "$item" | sed -E "s|$regex|\1|g")" || { error "Can't parse address from whitelist"; exit 1; }
    mask="$(echo "$item" | sed -E "s|$regex|\2|g")" || { error "Can't parse mask from whitelist"; exit 1; }
    port="$(echo "$item" | sed -E "s|$regex|\3|g")" || { error "Can't parse port from whitelist"; exit 1; }
    protocol="$(echo "$item" | sed -E "s|$regex|\4|g")" || { error "Can't parse protocol from whitelist"; exit 1; }

    if [[ "$mask" != '32' ]]; then
      if [[ "$port" != '*' ]]; then
        if [[ "$protocol" != '*' ]]; then
          iptables --verbose --append FORWARD --destination "$address" --jump ACCEPT || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        else
          iptables --verbose --append FORWARD --protocol "$protocol" --destination "$address" --jump ACCEPT || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        fi
      else
        if [[ "$protocol" != '*' ]]; then
          iptables --verbose --append FORWARD --destination "$address" --dport "$port" --jump ACCEPT || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        else
          iptables --verbose --append FORWARD --protocol "$protocol" --destination "$address"  --dport "$port" --jump ACCEPT || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        fi
      fi
    else
      if [[ "$port" != '*' ]]; then
        if [[ "$protocol" != '*' ]]; then
          iptables --verbose --append FORWARD --destination "$address/$mask" --jump ACCEPT || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        else
          iptables --verbose --append FORWARD --protocol "$protocol" --destination "$address/$mask" --jump ACCEPT || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        fi
      else
        if [[ "$protocol" != '*' ]]; then
          iptables --verbose --append FORWARD --destination "$address/$mask" --dport "$port" --jump ACCEPT || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        else
          iptables --verbose --append FORWARD --protocol "$protocol" --destination "$address/$mask"  --dport "$port" --jump ACCEPT || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        fi
      fi
    fi
  done
fi

if [[ "$BLACKLIST_ENABLED" == 1 ]]; then
  if [[ "$BLACKLIST_ENABLED" == 1 ]]; then
    error "Blacklist and whitelist enabled simultaneously"
    exit 1
  fi

  iptables --verbose --policy FORWARD ACCEPT || { error "$you_need_run_container_in_privileged_mode"; exit 1; }

  # shellcheck disable=SC2207
  array=($(echo "$BLACKLIST" | sed 's/ /;/g' | sed 's/,/ /g'))
  regex="^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/([0-9\*]+);([0-9\*]+)/([A-Za-z\*]+)$"

  for item in "${array[@]}"; do
    log "Blacklist ${item//;/ }"

    address="$(echo "$item" | sed -E "s|$regex|\1|g")" || { error "Can't parse address from blacklist"; exit 1; }
    mask="$(echo "$item" | sed -E "s|$regex|\2|g")" || { error "Can't parse mask from blacklist"; exit 1; }
    port="$(echo "$item" | sed -E "s|$regex|\3|g")" || { error "Can't parse port from blacklist"; exit 1; }
    protocol="$(echo "$item" | sed -E "s|$regex|\4|g")" || { error "Can't parse protocol from blacklist"; exit 1; }

    if [[ "$mask" != '32' ]]; then
      if [[ "$port" != '*' ]]; then
        if [[ "$protocol" != '*' ]]; then
          iptables --verbose --append FORWARD --destination "$address" --jump DROP || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        else
          iptables --verbose --append FORWARD --protocol "$protocol" --destination "$address" --jump DROP || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        fi
      else
        if [[ "$protocol" != '*' ]]; then
          iptables --verbose --append FORWARD --destination "$address" --dport "$port" --jump DROP || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        else
          iptables --verbose --append FORWARD --protocol "$protocol" --destination "$address"  --dport "$port" --jump DROP || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        fi
      fi
    else
      if [[ "$port" != '*' ]]; then
        if [[ "$protocol" != '*' ]]; then
          iptables --verbose --append FORWARD --destination "$address/$mask" --jump DROP || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        else
          iptables --verbose --append FORWARD --protocol "$protocol" --destination "$address/$mask" --jump DROP || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        fi
      else
        if [[ "$protocol" != '*' ]]; then
          iptables --verbose --append FORWARD --destination "$address/$mask" --dport "$port" --jump DROP || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        else
          iptables --verbose --append FORWARD --protocol "$protocol" --destination "$address/$mask"  --dport "$port" --jump DROP || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
        fi
      fi
    fi
  done
fi

log "Accept all traffic"
iptables --verbose --policy INPUT ACCEPT || { error "$you_need_run_container_in_privileged_mode"; exit 1; }
iptables --verbose --policy OUTPUT ACCEPT || { error "$you_need_run_container_in_privileged_mode"; exit 1; }

openvpn --config "$WORK_DIR/server.conf" &
