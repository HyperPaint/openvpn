#!/bin/bash

source "/root/scripts/.env"

source "/root/scripts/hbdl/log.sh"

you_need_run_container_in_privileged_mode="You need run container in privileged mode"

log "Drop all traffic"
iptables --verbose --policy INPUT DROP || { error "$you_need_run_container_in_privileged_mode"; return 1; }
iptables --verbose --policy FORWARD DROP || { error "$you_need_run_container_in_privileged_mode"; return 1; }
iptables --verbose --policy OUTPUT DROP || { error "$you_need_run_container_in_privileged_mode"; return 1; }

log "Flush tables"
iptables --verbose --flush || { error "$you_need_run_container_in_privileged_mode"; return 1; }
iptables --verbose --table nat --flush || { error "$you_need_run_container_in_privileged_mode"; return 1; }

if [[ -d "/dev/net" ]]; then
  log "/dev/net found"
else
  mkdir "/dev/net" || { error "$you_need_run_container_in_privileged_mode"; return 1; }
  log "/dev/net created"
fi

if [[ -c "/dev/net/tun" ]]; then
  log "/dev/net/tun found"
else
  mknod /dev/net/tun c 10 200 || { error "$you_need_run_container_in_privileged_mode"; return 1; }
  log "/dev/net/tun created"
fi

if [[ "$VPN_NAT_ENABLE" -eq 1 ]]; then
  vpn_nat=("$VPN_NAT")

  # shellcheck disable=SC2068
  for item in ${vpn_nat[@]}; do
    log "Enable NAT from $item"
    iptables --verbose --table nat --append POSTROUTING --source "$item" --jump MASQUERADE || { error "$you_need_run_container_in_privileged_mode"; return 1; }
  done

  if [[ "$(sysctl -n net.ipv4.ip_forward)" -eq 0 ]]; then
    sysctl net.ipv4.ip_forward=1 || { error "You need execute 'sysctl net.ipv4.ip_forward=1' at host system";  return 1; }
  fi
fi

if [ "$VPN_LAN_DISABLE" -eq 1 ]; then
  vpn_lan_from=("$VPN_LAN_FROM")
  vpn_lan_to=("$VPN_LAN_TO")

  # shellcheck disable=SC2068
  for from in ${vpn_lan_from[@]}; do
    # shellcheck disable=SC2068
    for to in ${vpn_lan_to[@]}; do
      log "Disable LAN from $from to $to"
      iptables --verbose --append FORWARD --source "$from" --destination "$to" --jump DROP || { error "$you_need_run_container_in_privileged_mode"; return 1; }
      log "Disable LAN from $to to $from"
      iptables --verbose --append FORWARD --source "$to" --destination "$from" --jump DROP || { error "$you_need_run_container_in_privileged_mode"; return 1; }
    done
  done
fi

log "Accept all traffic"
iptables --verbose --policy INPUT ACCEPT || { error "$you_need_run_container_in_privileged_mode"; return 1; }
iptables --verbose --policy FORWARD ACCEPT || { error "$you_need_run_container_in_privileged_mode"; return 1; }
iptables --verbose --policy OUTPUT ACCEPT || { error "$you_need_run_container_in_privileged_mode"; return 1; }

openvpn --config "$WORK_DIR/server.conf" &
