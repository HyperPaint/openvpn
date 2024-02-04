#!/bin/sh
author="hyperpaint"
name="openvpn-server"
tag="3"
docker build -t "$author/$name:$tag" .
