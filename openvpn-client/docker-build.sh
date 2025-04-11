#!/bin/bash

author="hyperpaint"
name="openvpn-client"
build_version="1.0.0"
openvpn_version="2.6.14-r0"

docker build -t "$author/$name:$build_version-$openvpn_version" .
