#!/bin/bash
# Bash is needed for arrays

pid=$$

trap "stop_template" 2 15

log() {
  # ISO-8601
  echo "[$(date '+%FT%TZ')] [$0] $1"
}

error() {
  # ISO-8601
  echo "[$(date '+%FT%TZ')] [$0] $1" 1>&2
}

prepare_app() {
  certs_directory="/root/certs"
  certs_cn_ca="$CERTS_CN_BASE-ca"
  certs_generate_subj_ca="/CN=$certs_cn_ca"

  if [ -f "$certs_directory/ca.key" ]; then
    log "$certs_directory/ca.key found"
  else
    openssl genrsa -out "$certs_directory/ca.key" "$CERTS_KEY_POWER"
    chmod 754 "$certs_directory/ca.key"
    log "$certs_directory/ca.key created"
  fi

  if [ -f "$certs_directory/ca.pem" ]; then
    log "$certs_directory/ca.pem found"
  else
    openssl req -new -key "$certs_directory/ca.key" -out "$certs_directory/ca.csr" -subj "$certs_generate_subj_ca"
    chmod 754 "$certs_directory/ca.csr"
    log "$certs_directory/ca.csr created"
    openssl x509 -days "$CERTS_GENERATE_DAYS" -req -in "$certs_directory/ca.csr" -key "$certs_directory/ca.key" -out "$certs_directory/ca.pem"
    chmod 754 "$certs_directory/ca.pem"
    log "$certs_directory/ca.pem created"
  fi

  certs_cn_server="$CERTS_CN_BASE-server"
  certs_generate_subj_server="/CN=$certs_cn_server"

  if [ -f "$certs_directory/server.key" ]; then
    log "$certs_directory/server.key found"
  else
    openssl genrsa -out "$certs_directory/server.key" "$CERTS_KEY_POWER"
    chmod 754 "$certs_directory/server.key"
    log "$certs_directory/server.key created"
  fi

  if [ -f "$certs_directory/server.pem" ]; then
    log "$certs_directory/server.pem found"
  else


    openssl req -new -key "$certs_directory/server.key" -out "$certs_directory/server.csr" -subj "$certs_generate_subj_server"
    chmod 754 "$certs_directory/server.csr"
    log "$certs_directory/server.csr created"
    openssl x509 -days "$CERTS_GENERATE_DAYS" -req -in "$certs_directory/server.csr" -CA "$certs_directory/ca.pem" -CAkey "$certs_directory/ca.key" -CAcreateserial -out "$certs_directory/server.pem"
    chmod 754 "$certs_directory/server.pem"
    log "$certs_directory/server.pem created"
  fi

  if [ -f "$certs_directory/diffie-hellman.pem" ]; then
    log "$certs_directory/diffie-hellman.pem found"
  else
    openssl dhparam -out "$certs_directory/diffie-hellman.pem" "$CERTS_KEY_POWER" 2>/dev/null # No output
    chmod 754 "$certs_directory/diffie-hellman.pem"
    log "$certs_directory/diffie-hellman.pem created"
  fi

  if [ -f "$certs_directory/tls-auth.key" ]; then
    log "$certs_directory/tls-auth.key found"
  else
    openvpn --genkey tls-auth "$certs_directory/tls-auth.key"
    chmod 754 "$certs_directory/tls-auth.key"
    log "$certs_directory/tls-auth.key created"
  fi

  if [ -f "/root/server.conf" ]; then
    log "/root/server.conf found"
  else
    error "/root/server.conf not found"
    return 1
  fi
}

start_app() {
  you_need_run_container_in_privileged_mode="You need run container in privileged mode"

  log "Drop all traffic"
  iptables --verbose --policy INPUT DROP || { error "$you_need_run_container_in_privileged_mode"; return 1; }
  iptables --verbose --policy FORWARD DROP || { error "$you_need_run_container_in_privileged_mode"; return 1; }
  iptables --verbose --policy OUTPUT DROP || { error "$you_need_run_container_in_privileged_mode"; return 1; }

  log "Flush tables"
  iptables --verbose --flush || { error "$you_need_run_container_in_privileged_mode"; return 1; }
  iptables --verbose --table nat --flush || { error "$you_need_run_container_in_privileged_mode"; return 1; }

  if [ -d "/dev/net" ]; then
    log "/dev/net found"
  else
    mkdir "/dev/net" || { error "$you_need_run_container_in_privileged_mode"; return 1; }
    log "/dev/net created"
  fi

  if [ -c "/dev/net/tun" ]; then
    log "/dev/net/tun found"
  else
    mknod /dev/net/tun c 10 200 || { error "$you_need_run_container_in_privileged_mode"; return 1; }
    log "/dev/net/tun created"
  fi

  if [ "$VPN_NAT_ENABLE" -eq 1 ]; then
    vpn_nat=("$VPN_NAT")
    for item in ${vpn_nat[*]}
    do
      log "NAT enable for $item"
      iptables --verbose --table nat --append POSTROUTING --source "$item" --jump MASQUERADE || { error "$you_need_run_container_in_privileged_mode"; return 1; }
    done
    if [ "$(sysctl -n net.ipv4.ip_forward)" -eq 0 ]; then
      sysctl net.ipv4.ip_forward=1 || { error "You need execute 'sysctl net.ipv4.ip_forward=1' at host system";  return 1; }
    fi
  fi

  if [ "$VPN_LAN_DISABLE" -eq 1 ]; then
    vpn_lan_from=("$VPN_LAN_FROM")
    vpn_lan_to=("$VPN_LAN_TO")
    for from in ${vpn_lan_from[*]}
    do
      for to in ${vpn_lan_to[*]}
      do
        log "LAN disable from $from to $to"
        iptables --verbose --append FORWARD --source "$from" --destination "$to" --jump DROP || { error "$you_need_run_container_in_privileged_mode"; return 1; }
        log "LAN disable from $to to $from"
        iptables --verbose --append FORWARD --source "$to" --destination "$from" --jump DROP || { error "$you_need_run_container_in_privileged_mode"; return 1; }
      done
    done
  fi

  log "Accept all traffic"
  iptables --verbose --policy INPUT ACCEPT || { error "$you_need_run_container_in_privileged_mode"; return 1; }
  iptables --verbose --policy FORWARD ACCEPT || { error "$you_need_run_container_in_privileged_mode"; return 1; }
  iptables --verbose --policy OUTPUT ACCEPT || { error "$you_need_run_container_in_privileged_mode"; return 1; }

  # Starting OpenVPN
  openvpn --config "/root/server.conf" &
}

stop_app() {
  :
}

### Don't touch ###

prepare_template() {
  log "Preparing..."
  prepare_date=$(date '+%s')
  
  prepare_app

  wait
  prepared_time=$(echo "$(date '+%s') - $prepare_date" | bc)
  log "Prepared in $prepared_time seconds"
  return 0
}

start_template() {
  log "Starting..."
  start_date=$(date '+%s')
  
  start_app

  pid=$!
  if [ $pid = -1 ]; then
    error "Can't start process"
    return 1
  else
    started_time=$(echo "$(date '+%s') - $start_date" | bc)
    log "Started in $started_time seconds"
    wait
    return 0
  fi
}

stop_template() {
  log "Stopping..."
  stop_date=$(date '+%s')

  stop_app

  if [ $pid = $$ ]; then
    return 0
  else
    log "Killing pid $pid"
    kill -15 $pid || error "Can't kill pid $pid"
    wait $pid
  fi
  stopped_time=$(echo "$(date '+%s') - $stop_date" | bc)
  log "Stopped in $stopped_time seconds"
  return 0
}

sleep_app() {
  error "Something went wrong"
  error "Sleeping 10 minutes..."
  sleep "10m"
  exit 1
}

if prepare_template; then
    start_template
else
    sleep_app
fi

log "Exited"
