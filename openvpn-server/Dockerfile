FROM hyperpaint/alpine:3-base

# OpenVPN & OpenSSL & IP tables & bash for arrays
RUN apk add openvpn openssl iptables bash

# Файлы
COPY --chown=root:root --chmod=755 ./files/ /

# Default
ENV CERTS_KEY_POWER="2048"
ENV CERTS_CN_BASE="openvpn"
ENV CERTS_GENERATE_DAYS="3600"

ENV VPN_NAT_ENABLE="1"
ENV VPN_NAT="10.0.0.0/8"
ENV VPN_LAN_DISABLE="1"
ENV VPN_LAN_FROM="10.0.0.0/8"
ENV VPN_LAN_TO="172.16.0.0/12 192.168.0.0/16"

EXPOSE 1194

# Запуск
WORKDIR "/root/"
CMD ["/bin/bash","-c","/root/scripts/start.sh"]
