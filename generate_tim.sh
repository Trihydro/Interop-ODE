#!/bin/bash

# This script is used to generate a TIM (Traveler Information Message) from a JSON file using the
# Operational Data Environment (ODE). It sends the JSON file to the ODE, retrieves the TIM from the ODE logs,
# extracts the HEX value, and saves it to a file with the same name as the input file but with a .uper extension.


if [ $# -ne 1 ]; then
    echo "Usage: ./generate_tim.sh <filename>"
    exit 1
fi

filename=$1

ensureNetTools() {
  echo "Checking if net-tools is installed..."
  if ! [ -x "$(command -v netstat)" ]; then
  echo "net-tools is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install net-tools
  fi
}

# Set up the .env file
setupEnv() {
  # if .env file does not exist, create it
  if [ ! -f .env ]; then
    echo "Setting up .env file..."
    if [ -z $DOCKER_HOST_IP ]
      then
          ensureNetTools
          export DOCKER_HOST_IP=$(ifconfig | grep -A 1 'inet ' | grep -v 'inet6\|127.0.0.1' | awk '{print $2}' | grep -E '^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-1]\.|^192\.168\.' | head -n 1)
      fi
      if [ -z $DOCKER_HOST_IP ]
      then
          echo "DOCKER_HOST_IP is not set and could not be determined. Exiting."
          exit 1
      fi

      # write DOCKER_HOST_IP to .env
      echo "DOCKER_HOST_IP=$DOCKER_HOST_IP" > .env

      # write DOCKER_SHARED_VOLUME to .env
      echo "DOCKER_SHARED_VOLUME=$PWD/shared" >> .env
  elif [ -f .env ]; then
    echo "Identified existing .env file..."
  fi
}

# if .env exists, grab DOCKER_HOST_IP from it
if [ -f .env ]; then
    echo "Sourcing .env file..."
    export $(cat .env | xargs)
else
    setupEnv
fi

validate_arguments() {
    if [ ! -f $filename ]; then
        echo "File not found!" Check the path and try again.
        exit 1
    fi

    if [ ! -f $filename ]; then
        echo "File is empty! Please provide a valid json file."
        exit 1
    fi
}

sendFileToOde() {
    success=false
    while [ $success == false ]; do
        # check if ODE is running
        if [ $(docker ps -q -f name=ode | wc -l) -eq 0 ]; then
            echo "ODE is not running. Please start ODE first."
            exit 1
        fi
        # send file to ODE
        echo "Sending $filename to ODE"
        response=$(curl -X POST http://$DOCKER_HOST_IP:8080/tim -H 'Content-Type: application/json' --data "@$filename" 2>/dev/null)
        # if "{"success":"true"}" not found in response
        if [[ $response != *"{\"success\":\"true\"}"* ]]; then
            echo "Failed to send file to ODE. Trying again..."
            sleep 3
            continue
        fi
        echo "File sent successfully! Waiting for ODE to process the file..."
        sleep 5
        success=true
    done
}

grabLatestLine() {
    # grab latest line containing "Encoded message - phase 1:" from ODE logs
    latest_line=$(docker compose logs ode | grep 'Encoded message - phase 1:' | tail -n 1)
    if [ -z "$latest_line" ]; then
        echo "TIM not found in ODE logs. Please try again."
        exit 1
    fi
}

extractHexValue() {
    # extract HEX value from the line
    hex_value=$(echo $latest_line | grep -oP '(?<=Encoded message - phase 1: ).*')
    if [ -z "$hex_value" ]; then
        echo "Failed to extract HEX value from the line. Please try again."
        exit 1
    fi
}

saveHexToFile() {
    # save hex to file with same name as input file but replace .json with .uper
    filenameWithoutExtention=$(echo $filename | cut -f 1 -d '.')
    echo $hex_value > ${filenameWithoutExtention}.uper
}

validate_arguments
sendFileToOde
grabLatestLine
extractHexValue
saveHexToFile

echo ""
echo "The TIM has been generated and saved to ${filenameWithoutExtention}.uper as an UPER encoded hex string."
echo ""
