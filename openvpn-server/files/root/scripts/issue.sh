#!/bin/bash

source "/root/scripts/.env"

source "/root/scripts/hbdl/log.sh"

client_name="$1"

client_key_file="$CERTS_DIR/client_$client_name.key"
client_csr_file="$CERTS_DIR/client_$client_name.csr"
client_crt_file="$CERTS_DIR/client_$client_name.crt"

if [[ -z "$client_name" ]]; then
  error "Client's name is not specified"
  exit 1
fi

if [[ -f "$client_key_file" ]]; then
  log "$client_key_file found"
else
  log "$client_key_file not found, creating..."

  openssl genrsa -out "$client_key_file" "$KEY_POWER"
  chmod 755 "$client_key_file"
  log "$client_key_file created"
fi

if [ -f "$client_crt_file" ]; then
  log "$client_crt_file found"
else
  log "$client_crt_file not found, creating..."

  openssl req -new -key "$client_key_file" -subj "${CERTS_DN_CLIENT_BASE}_${client_name}" -out "$client_csr_file"
  chmod 755 "$client_csr_file"
  log "$client_csr_file created"

  openssl x509 -req -in "$client_csr_file" -days "$ISSUE_DAYS" -CA "$CERTS_DIR/ca.crt" -CAkey "$CERTS_DIR/ca.key" -CAcreateserial -out "$client_crt_file"
  chmod 755 "$client_crt_file"
  log "$client_crt_file created"
fi

if [[ -f "$CCD_DIR/client_$client_name" ]]; then
  log "$CCD_DIR/client_$client_name ccd found"
else
  log "$CCD_DIR/client_$client_name ccd not found, creating..."

  touch "$CCD_DIR/client_$client_name"

  log "$CCD_DIR/client_$client_name ccd created"
fi

/root/scripts/ovpn.sh "$client_name" "$client_key_file" "$client_crt_file"
