FROM alpine:3.21.3

RUN apk add bash openssl iptables openvpn=2.6.12-r1

COPY --chown=root:root --chmod=755 ./files/ /
COPY --chown=root:root --chmod=755 ./hyperpaint-bash-docker-lib/ /root/scripts/hbdl/

ENV KEY_POWER="2048"
ENV ISSUE_DAYS="3600"

ENV VPN_NAT_ENABLE="1"
ENV VPN_NAT="10.0.0.0/8"
ENV VPN_LAN_DISABLE="1"
ENV VPN_LAN_FROM="10.0.0.0/8"
ENV VPN_LAN_TO="10.0.0.0/8 172.16.0.0/12 192.168.0.0/16"

ENV OPENVPN_AUTO_CONFIG="tcp"

EXPOSE 1194/tcp
EXPOSE 1194/udp

WORKDIR "/root/scripts/"
ENTRYPOINT ["/bin/bash","-c","/root/scripts/hbdl/entrypoint.sh"]
