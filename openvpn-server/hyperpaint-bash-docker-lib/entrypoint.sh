#!/bin/bash

trap "kill_command" 2 15

source "/root/scripts/hbdl/log.sh"

prepare() {
    log "Preparing..."
    prepare_date=$(date "+%s")

    if [[ -f "/root/scripts/prepare.sh" ]]; then
      source "/root/scripts/prepare.sh"
    fi

    wait

    prepared_time=$(echo "$(date '+%s') - $prepare_date" | bc)
    log "Prepared in $prepared_time seconds"
    return 0
}

start() {
  log "Starting..."
  start_date=$(date "+%s")

  if [[ -f "/root/scripts/start.sh" ]]; then
    source "/root/scripts/start.sh"
  fi

  if [[ "$(jobs | wc -l)" == 0 ]]; then
    error "Can't start application, exiting..."
    exit 1
  fi

  started_time=$(echo "$(date '+%s') - $start_date" | bc)
  log "Started in $started_time seconds"
  return 0
}

stop() {
  log "Stopping..."
  stop_date=$(date "+%s")

  if [[ -f "/root/scripts/stop.sh" ]]; then
    source "/root/scripts/stop.sh"
  fi

  wait

  stopped_time=$(echo "$(date '+%s') - $stop_date" | bc)
  log "Stopped in $stopped_time seconds"
  return 0
}

kill_command() {
  log "Received kill command"
  stop
}

if prepare; then
  if start; then
    wait
  fi
fi

log "Exited"
