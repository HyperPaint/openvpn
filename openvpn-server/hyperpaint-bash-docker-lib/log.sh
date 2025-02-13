#!/bin/bash
# ISO-8601

log() {
  echo "[$(date '+%FT%TZ')] [$(basename "$0")] $1"
}

error() {
  echo "[$(date '+%FT%TZ')] [$(basename "$0")] $1" 1>&2
}
