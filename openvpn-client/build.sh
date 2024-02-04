#!/bin/sh
author="hyperpaint"
name="openvpn-client"
tag="1"
docker build -t "$author/$name:$tag" .
