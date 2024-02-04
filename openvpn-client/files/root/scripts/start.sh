#!/bin/sh

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
}

start_app() {
  # Starting OpenVPN
  openvpn --config "/root/client.ovpn" &
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
