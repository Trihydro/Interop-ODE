#!/bin/bash

# This script is used to generate a TIM (Traveler Information Message) from a JSON file using the
# Operational Data Environment (ODE). It sends the JSON file to the ODE, retrieves the TIM from the ODE logs,
# extracts the HEX value, and saves it to a file with the same name as the input file but with a .uper extension.


# if no argument is passed
if [ $# -eq 0 ]; then
    echo "No argument passed! Usage: ./generate_tim.sh <filename>"
    exit 1
fi

# if file doesn't exist
if [ ! -f "$1" ]; then
    echo "File not found!" Check the path and try again.
    exit 1
fi

filename=$1

# if file is empty
if [ ! -s "$filename" ]; then
    echo "File is empty! Please provide a valid json file."
    exit 1
fi

# retrieve IP address of the host machine
export DOCKER_HOST_IP=$(ifconfig | grep -A 1 'inet ' | grep -v 'inet6\|127.0.0.1' | awk '{print $2}' | grep -E '^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-1]\.|^192\.168\.' | head -n 1)

# send file to ODE
echo "Sending $filename to ODE"
response=$(curl -X POST http://$DOCKER_HOST_IP:8080/tim -H 'Content-Type: application/json' --data "@$filename" 2>/dev/null)
# if "{"success":"true"}" not found in response
if [[ $response != *"{\"success\":\"true\"}"* ]]; then
    echo "Failed to send file to ODE. Please try again."
    exit 1
fi
echo "File sent successfully! Waiting for ODE to process the file..."
sleep 1

# grab latest line containing "Encoded message - phase 1:" from ODE logs
latest_line=$(docker compose logs ode | grep 'Encoded message - phase 1:' | tail -n 1)
if [ -z "$latest_line" ]; then
    echo "TIM not found in ODE logs. Please try again."
    exit 1
fi

# extract HEX value from the line
hex_value=$(echo $latest_line | grep -oP '(?<=Encoded message - phase 1: ).*')

# save hex to file with same name as input file but replace .json with .uper
filenameWithoutExtention=$(echo $filename | cut -f 1 -d '.')
echo $hex_value > ${filenameWithoutExtention}.uper

echo ""
echo "The TIM has been successfully generated and saved to ${filenameWithoutExtention}.uper as an UPER encoded hex string."
echo ""
