#!/bin/bash

author="hyperpaint"
name="openvpn-server"
build_version="1.2.0"
openvpn_version="2.6.12-r1"

docker build -t "$author/$name:$build_version-$openvpn_version" .
