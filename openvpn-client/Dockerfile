FROM hyperpaint/alpine:3-base

# OpenVPN
RUN apk add openvpn

# Файлы
COPY --chown=root:root --chmod=755 ./files/ /

# Запуск
WORKDIR "/root/"
CMD ["/bin/sh","-c","/root/scripts/start.sh"]
