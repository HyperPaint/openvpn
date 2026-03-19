#!/bin/bash

author="hyperpaint"
name="openvpn-server"
build_version="1.3.0"
openvpn_version="2.6.16-r0"

docker build -t "$author/$name:$build_version-$openvpn_version" .
