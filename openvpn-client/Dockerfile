FROM alpine:3.21.3

RUN apk add bash openvpn=2.6.12-r1

COPY --chown=root:root --chmod=755 ./files/ /
COPY --chown=root:root --chmod=755 ./hyperpaint-bash-docker-lib/ /root/scripts/hbdl/

WORKDIR "/root/scripts/"
ENTRYPOINT ["/bin/bash","-c","/root/scripts/hbdl/entrypoint.sh"]
