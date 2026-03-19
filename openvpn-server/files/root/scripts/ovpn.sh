#!/bin/bash

source "/root/scripts/.env"

source "/root/scripts/hbdl/log.sh"

client_name="$1"
client_key_file="$2"
client_crt_file="$3"

ca_crt_file="$CERTS_DIR/ca.crt"
tls_auth_file="$CERTS_DIR/tls-auth.key"

if [[ -z "$client_name" ]]; then
  error "Client's name is not specified"
  exit 1
fi

if [[ -z "$client_key_file" ]]; then
  error "Client's key is not specified"
  exit 1
fi

if [[ -z "$client_crt_file" ]]; then
  error "Client's cert is not specified"
  exit 1
fi

if [[ -f "$client_key_file" ]]; then
  log "$client_key_file found"
else
  error "$client_key_file not found"
fi

if [[ -f "$client_crt_file" ]]; then
  log "$client_crt_file found"
else
  error "$client_crt_file not found"
fi

if [[ -f "$ca_crt_file" ]]; then
  log "$ca_crt_file found"
else
  error "$ca_crt_file not found"
fi

if [[ -f "$tls_auth_file" ]]; then
  log "$tls_auth_file found"
else
  error "$tls_auth_file not found"
fi

log "$OVPN_DIR/$client_name.ovpn creating..."
{
  echo 'client'
  echo 'dev tun'
  echo 'connect-retry 1 3'
  echo 'connect-timeout 10'
  echo 'resolv-retry infinite'
  echo 'nobind'
  echo ''
  echo '# BEGIN connections.txt'
  cat "$WORK_DIR/connections.txt"
  echo '# END connections.txt'
  echo ''
  echo 'allow-pull-fqdn'
  echo '#redirect-gateway def1 bypass-dhcp'
  echo '#dhcp-option DNS 8.8.8.8'
  echo '#dhcp-option DNS 8.8.4.4'
  echo '#route 8.8.8.8 255.255.255.255'
  echo '#route 8.8.4.4 255.255.255.255'
  echo ''
  echo '#fast-io' # udp, linux
  echo ''
  echo 'persist-key'
  echo 'persist-tun'
  echo ''
  echo 'mute-replay-warnings'
  echo ''
  echo '<ca>'
  cat "$ca_crt_file"
  echo '</ca>'
  echo '<key>'
  cat "$client_key_file"
  echo '</key>'
  echo '<cert>'
  cat "$client_crt_file"
  echo '</cert>'
  echo '<tls-auth>'
  cat "$tls_auth_file"
  echo '</tls-auth>'
  echo 'key-direction 1'
  echo ''
  echo 'keepalive 10 120'
  echo 'cipher AES-256-GCM'
  echo ''
  echo 'verb 3'
} > "$OVPN_DIR/$client_name.ovpn"
log "$OVPN_DIR/$client_name.ovpn created"
