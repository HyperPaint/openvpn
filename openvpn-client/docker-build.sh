#!/bin/bash

author="hyperpaint"
name="openvpn-client"
build_version="1.0.0"
openvpn_version="2.6.12-r1"

docker build -t "$author/$name:$build_version-$openvpn_version" .
