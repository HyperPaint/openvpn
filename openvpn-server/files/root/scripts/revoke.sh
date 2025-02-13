#!/bin/bash

source "/root/scripts/.env"

source "/root/scripts/hbdl/log.sh"

client_name="$1"

if [[ -z "$client_name" ]]; then
  error "Client's name is not specified"
  exit 1
fi

if [[ -f "$CCD_DIR/client_$client_name" ]]; then
  log "$CERTS_DIR/client_$client_name ccd found, deleting..."

  rm -f "$CCD_DIR/client_$client_name"

  log "$CERTS_DIR/client_$client_name ccd deleted"
else
  log "$CERTS_DIR/client_$client_name ccd not found"
fi

if [[ -f "$OVPN_DIR/$client_name.ovpn" ]]; then
  log "$OVPN_DIR/$client_name.ovpn found, deleting..."

  rm -f "$OVPN_DIR/$client_name.ovpn"

  log "$OVPN_DIR/$client_name.ovpn deleted"
else
  log "$OVPN_DIR/$client_name.ovpn not found"
fi
