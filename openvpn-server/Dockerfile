FROM alpine:3.21.3

RUN apk add bash curl openssl iptables openvpn=2.6.14-r0

COPY --chown=root:root --chmod=755 ./files/ /
COPY --chown=root:root --chmod=755 ./hyperpaint-bash-docker-lib/ /root/scripts/hbdl/

ENV KEY_POWER="2048"
ENV ISSUE_DAYS="3600"

ENV OPENVPN_AUTO_CONFIG="udp"
ENV OPENVPN_AUTO_CONFIG_SERVER="10.8.0.0 255.255.255.0"

ENV OPENVPN_SERVER_ADDRESS=""
ENV OPENVPN_SERVER_PORT="1194"

ENV OPENVPN_USERS_ENABLED="1"
ENV OPENVPN_USERS=""

ENV NAT_ENABLED="1"
ENV NAT="10.0.0.0/8"

ENV WHITELIST_ENABLED="0"
ENV WHITELIST="10.0.0.0/8 */*,172.16.0.0/12 */*,192.168.0.0/16 */*"

ENV BLACKLIST_ENABLED="1"
ENV BLACKLIST="10.0.0.0/8 */*,172.16.0.0/12 */*,192.168.0.0/16 */*"

EXPOSE 1194/tcp
EXPOSE 1194/udp

WORKDIR "/root/scripts/"
ENTRYPOINT ["/bin/bash","-c","/root/scripts/hbdl/entrypoint.sh"]
