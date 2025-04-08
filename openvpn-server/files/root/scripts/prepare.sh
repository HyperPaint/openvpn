#!/bin/bash

source "/root/scripts/.env"

source "/root/scripts/hbdl/log.sh"

# certs
if [ -d "$CERTS_DIR" ]; then
  log "$CERTS_DIR/ found"
else
  log "$CERTS_DIR/ not found, creating..."

  mkdir "$CERTS_DIR/"
  chmod 755 "$CERTS_DIR/"
  log "$CERTS_DIR/ created"
fi

# ca key
if [ -f "$CERTS_DIR/ca.key" ]; then
  log "$CERTS_DIR/ca.key found"
else
  log "$CERTS_DIR/ca.key not found, creating..."

  openssl genrsa -out "$CERTS_DIR/ca.key" "$KEY_POWER"
  chmod 755 "$CERTS_DIR/ca.key"
  log "$CERTS_DIR/ca.key created"
fi

# ca pem
if [ -f "$CERTS_DIR/ca.pem" ]; then
  log "$CERTS_DIR/ca.pem found"
else
  log "$CERTS_DIR/ca.pem not found, creating..."

  openssl req -new -key "$CERTS_DIR/ca.key" -subj "$CERTS_DN_CA" -out "$CERTS_DIR/ca.csr"
  chmod 755 "$CERTS_DIR/ca.csr"
  log "$CERTS_DIR/ca.csr created"

  openssl x509 -req -in "$CERTS_DIR/ca.csr" -days "$ISSUE_DAYS" -key "$CERTS_DIR/ca.key" -extfile "$WORK_DIR/openssl_ca.conf" -out "$CERTS_DIR/ca.pem"
  chmod 755 "$CERTS_DIR/ca.pem"
  log "$CERTS_DIR/ca.pem created"
fi

# server key
if [ -f "$CERTS_DIR/server.key" ]; then
  log "$CERTS_DIR/server.key found"
else
  log "$CERTS_DIR/server.key not found, creating..."

  openssl genrsa -out "$CERTS_DIR/server.key" "$KEY_POWER"
  chmod 755 "$CERTS_DIR/server.key"
  log "$CERTS_DIR/server.key created"
fi

# server pem
if [ -f "$CERTS_DIR/server.pem" ]; then
  log "$CERTS_DIR/server.pem found"
else
  log "$CERTS_DIR/server.pem not found, creating..."

  openssl req -new -key "$CERTS_DIR/server.key" -subj "$CERTS_DN_SERVER" -out "$CERTS_DIR/server.csr"
  chmod 755 "$CERTS_DIR/server.csr"
  log "$CERTS_DIR/server.csr created"

  openssl x509 -req -in "$CERTS_DIR/server.csr" -days "$ISSUE_DAYS" -CAkey "$CERTS_DIR/ca.key" -CA "$CERTS_DIR/ca.pem" -CAcreateserial -out "$CERTS_DIR/server.pem"
  chmod 755 "$CERTS_DIR/server.pem"
  log "$CERTS_DIR/server.pem created"
fi

# diffie hellman
if [ -f "$CERTS_DIR/diffie-hellman.pem" ]; then
  log "$CERTS_DIR/diffie-hellman.pem found"
else
  log "$CERTS_DIR/diffie-hellman.pem not found, creating..."

  openssl dhparam -out "$CERTS_DIR/diffie-hellman.pem" "$KEY_POWER"
  chmod 755 "$CERTS_DIR/diffie-hellman.pem"
  log "$CERTS_DIR/diffie-hellman.pem created"
fi

# openvpn tls-auth
if [ -f "$CERTS_DIR/tls-auth.key" ]; then
  log "$CERTS_DIR/tls-auth.key found"
else
  log "$CERTS_DIR/tls-auth.key not found, creating..."

  openvpn --genkey tls-auth "$CERTS_DIR/tls-auth.key"
  chmod 755 "$CERTS_DIR/tls-auth.key"
  log "$CERTS_DIR/tls-auth.key created"
fi

# ipp.txt
if [ -f "$WORK_DIR/ipp.txt" ]; then
  log "$WORK_DIR/ipp.txt found"
else
  log "$WORK_DIR/ipp.txt not found, creating..."

  touch "$WORK_DIR/ipp.txt"
  chmod 755 "$WORK_DIR/ipp.txt"
  log "$WORK_DIR/ipp.txt created"
fi

# ccd
if [ -d "$CCD_DIR/" ]; then
  log "$CCD_DIR found"
else
  log "$CCD_DIR not found, creating..."

  mkdir "$CCD_DIR"
  chmod 755 "$CCD_DIR"
  log "$CCD_DIR created"
fi

# ovpn
if [ -d "$OVPN_DIR/" ]; then
  log "$OVPN_DIR/ found"
else
  log "$OVPN_DIR/ not found, creating..."

  mkdir "$OVPN_DIR/"
  chmod 755 "$OVPN_DIR/"
  log "$OVPN_DIR/ created"
fi

# server.conf
if [[ "$OPENVPN_AUTO_CONFIG" == "tcp" ]]; then
  log "VPN auto-config as TCP server"

  {
    echo 'dev tun'
    echo 'proto tcp'
    echo 'port 1194'
    echo ''
    echo "ca $CERTS_DIR/ca.pem"
    echo "key $CERTS_DIR/server.key"
    echo "cert $CERTS_DIR/server.pem"
    echo "dh $CERTS_DIR/diffie-hellman.pem"
    echo "tls-auth $CERTS_DIR/tls-auth.key 0"
    echo ''
    echo 'topology subnet'
    echo 'client-to-client'
    echo "server $OPENVPN_AUTO_CONFIG_SERVER"
    echo ''
    echo "ifconfig-pool-persist $WORK_DIR/ipp.txt"
    echo "client-config-dir $CCD_DIR"
    echo 'ccd-exclusive'
    echo ''
    if [[ -f "$WORK_DIR/push" ]]; then
      cat "$WORK_DIR/push"
    fi
    echo ''
    echo 'keepalive 1 3'
    echo 'cipher AES-256-GCM'
    echo 'max-clients 255'
    echo ''
    echo 'persist-key'
    echo 'persist-tun'
    echo ''
    echo 'verb 3'
  } > "$WORK_DIR/server.conf"

  log "$WORK_DIR/server.conf created"
fi

if [[ "$OPENVPN_AUTO_CONFIG" == "udp" ]]; then
  log "VPN auto-config as UDP server"

  {
    echo 'dev tun'
    echo 'proto udp'
    echo 'port 1194'
    echo ''
    echo "ca $CERTS_DIR/ca.pem"
    echo "key $CERTS_DIR/server.key"
    echo "cert $CERTS_DIR/server.pem"
    echo "dh $CERTS_DIR/diffie-hellman.pem"
    echo "tls-auth $CERTS_DIR/tls-auth.key 0"
    echo ''
    echo 'topology subnet'
    echo 'client-to-client'
    echo "server $OPENVPN_AUTO_CONFIG_SERVER"
    echo ''
    echo "ifconfig-pool-persist $WORK_DIR/ipp.txt"
    echo "client-config-dir $CCD_DIR"
    echo 'ccd-exclusive'
    echo ''
    if [[ -f "$WORK_DIR/push" ]]; then
      cat "$WORK_DIR/push"
    fi
    echo ''
    echo 'fast-io' # linux, udp
    echo ''
    echo 'keepalive 1 3'
    echo 'cipher AES-256-GCM'
    echo 'max-clients 255'
    echo ''
    echo 'persist-key'
    echo 'persist-tun'
    echo ''
    echo 'verb 3'
    echo ''
    echo 'explicit-exit-notify' # udp
  } > "$WORK_DIR/server.conf"

  log "$WORK_DIR/server.conf created"
fi

log "VPN auto-config disabled"

if [[ -f "$WORK_DIR/server.conf" ]]; then
  log "$WORK_DIR/server.conf found"
else
  error "$WORK_DIR/server.conf not found"
  exit 1
fi

/root/scripts/users.sh
