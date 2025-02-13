#!/bin/bash

source "/root/scripts/.env"

source "/root/scripts/hbdl/log.sh"

client_name="$1"

if [[ -z "$client_name" ]]; then
  error "Client's name is not specified"
  exit 1
fi

if [[ -f "$CERTS_DIR/client_$client_name.key" ]]; then
  log "$CERTS_DIR/client_$client_name.key found"
else
  error "$CERTS_DIR/client_$client_name.key not found"
  exit 1
fi

if [ -f "$CERTS_DIR/client_$client_name.pem" ]; then
  log "$CERTS_DIR/client_$client_name.pem found, recreating..."

  openssl req -new -key "$CERTS_DIR/client_$client_name.key" -subj "${CERTS_DN_CLIENT_BASE}_${client_name}" -out "$CERTS_DIR/client_$client_name.csr"
  chmod 755 "$CERTS_DIR/client_$client_name.csr"
  log "$CERTS_DIR/client_$client_name.csr created"

  openssl x509 -req -in "$CERTS_DIR/client_$client_name.csr" -days "$ISSUE_DAYS" -CA "$CERTS_DIR/ca.pem" -CAkey "$CERTS_DIR/ca.key" -CAcreateserial -out "$CERTS_DIR/client_$client_name.pem"
  chmod 755 "$CERTS_DIR/client_$client_name.pem"
  log "$CERTS_DIR/client_$client_name.pem created"
else
  error "$CERTS_DIR/client_$client_name.pem not found"
fi

if [[ -f "$CCD_DIR/client_$client_name" ]]; then
  log "$CCD_DIR/client_$client_name ccd found"
else
  log "$CCD_DIR/client_$client_name ccd not found, creating..."

  touch "$CCD_DIR/client_$client_name"

  log "$CCD_DIR/client_$client_name ccd created"
fi

/root/scripts/ovpn.sh "$client_name" "$CERTS_DIR/client_$client_name.key" "$CERTS_DIR/client_$client_name.pem"
