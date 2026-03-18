FROM alpine:3.23.3

RUN apk add bash openvpn=2.6.16-r0

COPY --chown=root:root --chmod=755 ./files/ /
COPY --chown=root:root --chmod=755 ./hyperpaint-bash-docker-lib/ /root/scripts/hbdl/

WORKDIR "/root/scripts/"
ENTRYPOINT ["/bin/bash","-c","/root/scripts/hbdl/entrypoint.sh"]
