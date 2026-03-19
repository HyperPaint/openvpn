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
if [ -f "$CERTS_DIR/ca.crt" ]; then
  log "$CERTS_DIR/ca.crt found"
else
  log "$CERTS_DIR/ca.crt not found, creating..."

  openssl req -x509 -key "$CERTS_DIR/ca.key" -subj "$CERTS_DN_CA" -days "$ISSUE_DAYS" -addext "basicConstraints=critical,CA:true" -out "$CERTS_DIR/ca.crt"
  chmod 755 "$CERTS_DIR/ca.crt"
  log "$CERTS_DIR/ca.crt created"
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
if [ -f "$CERTS_DIR/server.crt" ]; then
  log "$CERTS_DIR/server.crt found"
else
  log "$CERTS_DIR/server.crt not found, creating..."

  openssl req -new -key "$CERTS_DIR/server.key" -subj "$CERTS_DN_SERVER" -out "$CERTS_DIR/server.csr"
  chmod 755 "$CERTS_DIR/server.csr"
  log "$CERTS_DIR/server.csr created"

  openssl x509 -req -in "$CERTS_DIR/server.csr" -days "$ISSUE_DAYS" -CAkey "$CERTS_DIR/ca.key" -CA "$CERTS_DIR/ca.crt" -CAcreateserial -out "$CERTS_DIR/server.crt"
  chmod 755 "$CERTS_DIR/server.crt"
  log "$CERTS_DIR/server.crt created"
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

# routes.txt
if [[ -f "$WORK_DIR/routes.txt" ]]; then
  log "$WORK_DIR/routes.txt found"
else
  {
    echo 'redirect-gateway def1 bypass-dhcp'
    echo 'dhcp-option DNS 8.8.8.8'
    echo 'dhcp-option DNS 8.8.4.4'
    echo 'route 8.8.8.8 255.255.255.255 vpn_gateway'
    echo 'route 8.8.4.4 255.255.255.255 vpn_gateway'
  } > "$WORK_DIR/routes.txt"

  log "$WORK_DIR/routes.txt created"
fi

# server.conf
if [[ -f "$WORK_DIR/server.conf" ]]; then
  log "$WORK_DIR/server.conf found"
else
  if [[ "$OPENVPN_AUTO_CONFIG" == "tcp" ]]; then
    log "VPN auto-config as TCP server"

    {
      echo 'dev tun'
      echo 'proto tcp'
      echo 'local 0.0.0.0'
      echo "port $OPENVPN_SERVER_PORT"
      echo ''
      echo "ca $CERTS_DIR/ca.crt"
      echo "key $CERTS_DIR/server.key"
      echo "cert $CERTS_DIR/server.crt"
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
      echo '# BEGIN routes.txt'
      while read -r line; do
        echo "push \"$line\""
      done < "$WORK_DIR/routes.txt"
      echo '# END routes.txt'
      echo ''
      echo 'keepalive 10 120'
      echo 'cipher AES-256-GCM'
      echo 'max-clients 255'
      echo ''
      echo 'persist-key'
      echo 'persist-tun'
      echo ''
      echo "status $WORK_DIR/status.log"
      echo ''
      echo 'verb 3'
    } > "$WORK_DIR/server.conf"

    log "$WORK_DIR/server.conf created"
  elif [[ "$OPENVPN_AUTO_CONFIG" == "udp" ]]; then
    log "VPN auto-config as UDP server"

    {
      echo 'dev tun'
      echo 'proto udp'
      echo 'local 0.0.0.0'
      echo "port $OPENVPN_SERVER_PORT"
      echo ''
      echo "ca $CERTS_DIR/ca.crt"
      echo "key $CERTS_DIR/server.key"
      echo "cert $CERTS_DIR/server.crt"
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
      echo '# BEGIN routes.txt'
      while read -r line; do
        echo "push \"$line\""
      done < "$WORK_DIR/routes.txt"
      echo '# END routes.txt'
      echo ''
      echo 'fast-io' # linux, udp
      echo ''
      echo 'keepalive 10 120'
      echo 'cipher AES-256-GCM'
      echo 'max-clients 255'
      echo ''
      echo 'persist-key'
      echo 'persist-tun'
      echo ''
      echo "status $WORK_DIR/status.log"
      echo ''
      echo 'verb 3'
      echo ''
      echo 'explicit-exit-notify 1' # udp
    } > "$WORK_DIR/server.conf"

    log "$WORK_DIR/server.conf created"
  else
    log "VPN auto-config disabled"

    error "$WORK_DIR/server.conf not found"
    exit 1
  fi
fi

# connections.txt
if [[ -z "$OPENVPN_SERVER_ADDRESS" ]]; then
  log 'Request to ifconfig.me ...'
  OPENVPN_SERVER_ADDRESS="$(curl "ifconfig.me")"
  export OPENVPN_SERVER_ADDRESS
fi

log "OpenVPN server address is $OPENVPN_SERVER_ADDRESS"
log "OpenVPN server port is $OPENVPN_SERVER_PORT"

if [[ -f "$WORK_DIR/connections.txt" ]]; then
  log "$WORK_DIR/connections.txt found"
elif [[ "$OPENVPN_AUTO_CONFIG" == "tcp" ]]; then
  {
    echo '<connection>'
    echo "    remote $OPENVPN_SERVER_ADDRESS $OPENVPN_SERVER_PORT tcp"
    echo '</connection>'
  } > "$WORK_DIR/connections.txt"

  log "$WORK_DIR/connections.txt created"
elif [[ "$OPENVPN_AUTO_CONFIG" == "udp" ]]; then
  {
    echo '<connection>'
    echo "    remote $OPENVPN_SERVER_ADDRESS $OPENVPN_SERVER_PORT udp"
    echo '    explicit-exit-notify 1'
    echo '</connection>'
  } > "$WORK_DIR/connections.txt"

  log "$WORK_DIR/connections.txt created"
else
  error "$WORK_DIR/connections.txt not found"
  exit 1
fi

# users
if [[ "$OPENVPN_USERS_ENABLED" == 1 ]]; then
  # shellcheck disable=SC2206
  array=(${OPENVPN_USERS//,/ })
  array_full="${array[*]}"

  for item in "$CCD_DIR"/*; do
    [[ -e "$item" ]] || break

    client="$(basename "${item/client_/}")"

    if [[ ! " $array_full " =~ [[:space:]]${client}[[:space:]] ]]; then
      log "Revoke $client"
      /root/scripts/revoke.sh "$client"
    fi
  done

  for item in "${array[@]}"; do
    if [[ ! -f "$CCD_DIR/client_$item" ]]; then
      log "Issue $item"
      /root/scripts/issue.sh "$item"
    fi
  done
fi
