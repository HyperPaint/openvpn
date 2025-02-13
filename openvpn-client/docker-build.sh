#!/bin/sh
author="hyperpaint"
name="openvpn-client"
tag="2"

docker build -t "$author/$name:$tag" .
