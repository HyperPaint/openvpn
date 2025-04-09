# OpenVPN

OpenVPN — это популярное программное обеспечение с открытым исходным кодом.
Обеспечивает защищенное соединение между устройствами через Интернет, шифруя данные и скрывая IP-адрес пользователя.
Поддерживает различные операционные системы и используется как в корпоративных сетях, так и для защиты личных данных в публичных Wi-Fi сетях.

## OpenVPN Server

Docker образ OpenVPN сервера с встроенной автоматизацией для быстрого развёртывания:

- содержит готовую конфигурацию, подходящую как для обхода блокировок, так и для организации безопасной связи между узлами сети
- при первом запуске самостоятельно создаёт полный криптографический слой, обеспечивая высокую степень защиты
- автоматически определяет свой IP-адрес в сети, упрощая настройку
- генерирует сертификаты для выбранных пользователей и удаляет лишних, поддерживая порядок и безопасность
- формирует OVPN-файлы сразу при добавлении нового пользователя, экономя ваше время

### Как использовать?

- установить [Docker](https://docs.docker.com/engine/install/).
- собрать образ ```git clone git@github.com:HyperPaint/openvpn.git && cd openvpn/openvpn-server && bash docker-build.sh```
- запустить одним из двух путей

Через docker run:

```
docker run -dit -e OPENVPN_AUTO_CONFIG="udp" -e OPENVPN_USERS="client1,client2,client3" -v ./certs:/root/certs:rw  -v ./ccd:/root/ccd:rw -v ./ovpn:/root/ovpn:rw --cap-add NET_ADMIN --device=/dev/net/tun hyperpaint/openvpn-server:1.2.0-2.6.12-r1
```

Или, лучше, через docker compose:

```
name: openvpn-server
services:

  udp:
    cap_add:
      - NET_ADMIN
    deploy:
      resources:
        limits:
          cpus: "1"
          memory: "32M"
        reservations:
          cpus: "0.1"
          memory: "32M"
    environment:
      OPENVPN_AUTO_CONFIG: "udp"
      OPENVPN_USERS: "client1,client2,client3"
    image: hyperpaint/openvpn-server:1.2.0-2.6.12-r1
    networks:
      - default
    ports:
      - "1194:1194/udp"
    restart: always
    volumes:
      - ./certs:/root/certs:rw
      - ./ccd:/root/ccd:rw
      - ./ovpn:/root/ovpn:rw
    devices:
      - /dev/net/tun

  tcp:
    cap_add:
      - NET_ADMIN
    deploy:
      resources:
        limits:
          cpus: "1"
          memory: "32M"
        reservations:
          cpus: "0.1"
          memory: "32M"
    environment:
      OPENVPN_AUTO_CONFIG: "tcp"
      OPENVPN_USERS: "client1,client2,client3"
    image: hyperpaint/openvpn-server:1.2.0-2.6.12-r1
    networks:
      - default
    ports:
      - "1194:1194/tcp"
    restart: always
    volumes:
      - ./certs:/root/certs:rw
      - ./ccd:/root/ccd:rw
      - ./ovpn:/root/ovpn:rw
    devices:
      - /dev/net/tun

networks:
  default:
```

```
docker compose up -d udp
```

```
docker compose up -d tcp
```

Важно! Контейнер создаёт все необходимые сертификаты, ключи и пользователей, поэтому при первом запуске или при изменении списка пользователей, необходимо запускать контейнеры по-очереди

После запуска в директории certs появятся все сгенерированные сертификаты и ключи, в директории ccd - все профили пользователей, в директории ovpn - клиентская конфигурация для подключения

### Как настроить под себя?

Ниже перечислены переменные, использующиеся в образе

|Переменная|Описание|Тип|Значение|
|-|-|-|-|
|KEY_POWER|Длина приватных ключей|Число|2048|
|ISSUE_DAYS|Время действия сертификатов в днях|Число|3600|
|OPENVPN_AUTO_CONFIG|Автоматическая настройка OpenVPN в UDP или TCP сервер|Строка|udp|
|OPENVPN_AUTO_CONFIG_SERVER|Часть параметра server в конфигурации OpenVPN для указания стандартной сети и её маски|Строка|10.8.0.0 255.255.255.0|
|OPENVPN_SERVER_ADDRESS|Адрес сервера OpenVPN, используется в OVPN-файлах, если пусто, определяется автоматически|Строка||
|OPENVPN_SERVER_PORT|Порт сервера OpenVPN, используется в конфигурации сервера и в OVPN-файлах|Число|1194|
|OPENVPN_USERS_ENABLED|Включено управление пользователями?|Число|1|
|OPENVPN_USERS|Никнейм пользователей без пробелов и спец. символов через запятую|Строка||
|NAT_ENABLED|Включён NAT?|Число|1|
|NAT|Сети для которых включён NAT в формате <IP-адрес сети>/<маска>|Строка|10.0.0.0/8|
|WHITELIST_ENABLED|Включен белый список?|Число|0|
|WHITELIST|Сети, доступ в которые не ограничен в формате <IP-адрес сети>/<маска> <порт>/<протокол>|Строка|10.0.0.0/8 \*/\*,172.16.0.0/12 \*/\*,192.168.0.0/16 \*/\*|
|BLACKLIST_ENABLED|Включен чёрный список?|Число|1|
|BLACKLIST|Сети, доступ в которые ограничен в формате <IP-адрес сети>/<маска> <порт>/<протокол>|Строка|10.0.0.0/8 \*/\*,172.16.0.0/12 \*/\*,192.168.0.0/16 \*/\*|

Важно! Белый и чёрный список не могут быть включены одновременно

## OpenVPN Client

Docker образ OpenVPN клиента

### Как использовать?

```
git clone git@github.com:HyperPaint/openvpn.git && cd openvpn/openvpn-client && bash docker-build.sh
```

```
docker run -dit -v ./client1.ovpn:/root/client.ovpn:ro --cap-add NET_ADMIN --device=/dev/net/tun hyperpaint/openvpn-client:1.0.0-2.6.12-r1
```

```
name: openvpn-client
services:

  client1:
    cap_add:
      - NET_ADMIN
    deploy:
      resources:
        limits:
          cpus: "1"
          memory: "32M"
        reservations:
          cpus: "0.1"
          memory: "32M"
    image: hyperpaint/openvpn-client:1.0.0-2.6.12-r1
    network_mode: host
    restart: always
    volumes:
      - ./client1.ovpn:/root/client.ovpn:ro
    devices:
      - /dev/net/tun
```
