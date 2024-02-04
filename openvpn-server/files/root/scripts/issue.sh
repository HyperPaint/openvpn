#!/bin/sh

log() {
  # ISO-8601
  echo "[$(date '+%FT%TZ')] [$0] $1"
}

error() {
  # ISO-8601
  echo "[$(date '+%FT%TZ')] [$0] $1" 1>&2
}

certs_directory="/root/certs"
certs_cn_client="$CERTS_CN_BASE-client"
certs_generate_subj_client="/CN=$certs_cn_client"

generate_client() {
  client="$1"
  if [ -n "$client" ]; then
    if [ -f "$certs_directory/client-$client.key" ]; then
      log "$certs_directory/client-$client.key found"
    else
      openssl genrsa -out "$certs_directory/client-$client.key" "$CERTS_KEY_POWER"
      chmod 754 "$certs_directory/client-$client.key"
      log "$certs_directory/client-$client.key created"
    fi

    if [ -f "$certs_directory/client-$client.csr" ]; then
      log "$certs_directory/client-$client.csr found"
    else
      openssl req -new -key "$certs_directory/client-$client.key" -out "$certs_directory/client-$client.csr" -subj "$certs_generate_subj_client-$client"
      chmod 754 "$certs_directory/client-$client.csr"
      log "$certs_directory/client-$client.csr created"
    fi

    if [ -f "$certs_directory/client-$client.pem" ]; then
      log "$certs_directory/client-$client.pem found"
    else
      openssl x509 -days "$CERTS_GENERATE_DAYS" -req -in "$certs_directory/client-$client.csr" -CA "$certs_directory/ca.pem" -CAkey "$certs_directory/ca.key" -CAcreateserial -out "$certs_directory/client-$client.pem"
      chmod 754 "$certs_directory/client-$client.pem"
      log "$certs_directory/client-$client.pem created"
    fi
  else
    error "Can't execute generate_client"
    return 1
  fi
  return 0
}

generate_client "$1"