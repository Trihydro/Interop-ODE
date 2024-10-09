#!/bin/bash

# This script is used to retrieve the IP address of the host machine that is running the docker containers. The `eth0` interface is used to determine the IP address.

ip_output=$(ifconfig eth0 2>/dev/null)
if [ -z "$ip_output" ]; then
    echo "Error: Network interface eth0 not found."
    exit 1
fi

inet_line=$(echo "$ip_output" | grep 'inet ' | grep -v 'inet6\|127.0.0.1')
if [ -z "$inet_line" ]; then
    echo "Error: No valid inet line found."
    exit 1
fi

ip_address=$(echo "$inet_line" | awk '{print $2}')
valid_ip=$(echo "$ip_address" | grep -E '^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-1]\.|^192\.168\.')
if [ -z "$valid_ip" ]; then
    echo "Error: No valid IP address found."
    exit 1
fi

export DOCKER_HOST_IP=$(echo "$valid_ip" | head -n 1)