#!/bin/bash

# Service has to start first - or we should move the consul stuff into the app.
/usr/local/bin/rebar-dhcp --server_ip=$EXTERNAL_IP --backing_store=consul --data_dir=digitalrebar/dhcp/database --auth_mode=KEY &

# Add rev-proxy matcher
echo '^dhcp/(.*)' | kv_put digitalrebar/public/revproxy/dhcp-mgmt-service/matcher

check_line="{\"tcp\": \"${IP%/*}:6755\", \"interval\": \"10s\", \"timeout\": \"2s\"}"
make_service dhcp 67 "$check_line"

OSD=$SERVICE_DEPLOYMENT
SERVICE_DEPLOYMENT="$OSD\", \"revproxy"
make_service dhcp-mgmt  6755 "$check_line"
SERVICE_DEPLOYMENT=$OSD
