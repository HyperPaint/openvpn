#!/bin/bash

source "/root/scripts/.env"

source "/root/scripts/hbdl/log.sh"

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