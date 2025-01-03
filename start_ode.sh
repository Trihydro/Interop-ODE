#!/bin/bash

# This script is used to start the Operational Data Environment (ODE) using docker compose.
# It checks if docker is installed, sets up the .env file, spins down existing containers if they exist,
# starts the containers, waits for the containers to start, and checks if the containers are running.


# Check if docker is installed
checkIfDockerInstalled() {
  echo "Checking if docker is installed..."
  if ! [ -x "$(command -v docker)" ]; then
    echo "Error: docker is not installed. Install here: https://docs.docker.com/get-docker/"
    exit 1
  fi
}

ensureNetTools() {
  echo "Checking if net-tools is installed..."
  if ! [ -x "$(command -v netstat)" ]; then
  echo "net-tools is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y net-tools
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
          # call retrieve_docker_host_ip.sh to get DOCKER_HOST_IP
          . retrieve_docker_host_ip.sh
          if [ $? -ne 0 ]; then
              echo "Failed to retrieve DOCKER_HOST_IP. Exiting."
              exit 1
          fi
      fi
      if [ -z $DOCKER_HOST_IP ]
      then
          echo "DOCKER_HOST_IP is not set and could not be determined. Exiting."
          exit 1
      fi

      # write DOCKER_HOST_IP to .env
      echo "DOCKER_HOST_IP=$DOCKER_HOST_IP" > .env

      # write DOCKER_SHARED_VOLUME to .env
      echo "DOCKER_SHARED_VOLUME=\"$PWD/shared\"" >> .env
  elif [ -f .env ]; then
    echo "Identified existing .env file..."
  fi
}

# Spin down existing containers if they exist
spinDownExistingContainers() {
  echo "Spinning down existing containers if they exist..."
  docker compose down > /dev/null 2>&1
}

# Start the containers
startContainers() {
  echo "Starting containers..."
  docker compose up -d
}

# Check if the containers are running
checkIfContainersAreRunning() {
  echo "Checking if containers are running..."
  # check if kafka, ode & aem containers are running
  if [ "$(docker ps -q -f name=ode)" ] && [ "$(docker ps -q -f name=kafka)" ] && [ "$(docker ps -q -f name=aem)" ] && [ "$(docker ps -q -f name=sdx)" ]; then
    echo "Most recent logs from the ODE container:"
    docker compose logs ode --tail 10
    echo ""
    echo "The Operational Data Environment is up and running!"
  else
    echo "The Operational Data Environment is not running. Please try again."
    exit 1
  fi
}

checkIfDockerInstalled
setupEnv
spinDownExistingContainers
startContainers

# wait for containers to start
echo "Waiting for containers to start..."
sleep 10

checkIfContainersAreRunning

# press button to continue
echo ""
echo "Press any key to continue..."
read -n 1 -s -r -p ""