# Interop-ODE
This repository contains a pre-configured instance of the [Operational Data Environment (ODE)](https://github.com/usdot-jpo-ode/jpo-ode) for the October 2024 Inter-Op Testing Event.

The purpose of this instance of the ODE is to provide users with the ability to generate messages in UPER encoded hex format corresponding to the J2735 ASN.1 specification. In order to do this, a subset of the ODE services have been configured to run in Docker containers. The services that are running in Docker containers are:
- [Kafka](https://kafka.apache.org/)
- [Operational Data Environment (ODE)](https://github.com/usdot-jpo-ode/jpo-ode)
- [Asn1_codec Encoder Module (AEM)](https://github.com/usdot-jpo-ode/asn1_codec)

To generate a message, a user can run the provided script `generate_tim.sh`. This script will generate a TIM message in UPER encoded hex format and save it to a file. The script relies on the ODE being started in order to generate the message.

## Prerequisites
### Docker
This repository uses Docker to run the ODE. If you do not have Docker installed, you can download it [here](https://www.docker.com/products/docker-desktop).

### Shell
This repository provides a bash script to start the ODE.

If you do not have a shell capable of running bash scripts (like [WSL](https://docs.docker.com/desktop/wsl/) or [Git Bash](https://gitforwindows.org/)), you will need to start the ODE manually. Instructions for starting the ODE manually are provided below.

## How to start the ODE
### Script
The `start_ode.sh` script will start the ODE with the necessary configuration for the Inter-Op Testing Event. To run the script, execute the following command:
```bash
./start_ode.sh
```

### Manual
To start the ODE manually, you will need to run through the following steps:
1. Copy `sample.env` to `.env` and update the DOCKER_HOST_IP variable with the IP address of your machine.
1. Run the following command to start the ODE:
```bash
docker compose up -d
```
1. Check that the kafka, ode and adm services are running by running the following command and examining the output:
```bash
docker compose ps
```
1. Check on the logs of the ode service to ensure that it has started successfully:
```bash
docker compose logs ode --tail 100
```

## How to generate messages
Note: Ensure your .env file doesn't have comments as it is read in by the generate script with xargs and the comments will cause the script to fail.

To generate a message, run the following command:
```bash
./generate_tim.sh data/tim.json
```

A new file containing the UPER encoded hex message will be created in the same directory as the input file.

### Note 
The `generate_tim.sh` script must not be run in parallel.

Running the TIM generation script in multiple terminals simultaneously can lead to mismatches between the retrieved HEX and the input files. This occurs because the script captures the latest HEX output without confirming whether the decoded UPER message matches the original TIM JSON input.

To avoid this issue, run the script in a single terminal and wait for the script to complete before running it again.

## How to stop the ODE
Run the following command to stop the ODE:
```bash
docker compose down
```

## Note on eth0
In order to run the ODE in Docker, the `DOCKER_HOST_IP` environment variable must be set to the IP address of the machine running Docker. The provided scripts use the `retrieve_docker_host_ip.sh` script to retrieve the IP address of the machine running Docker. The `retrieve_docker_host_ip.sh` script targets the `eth0` interface to retrieve the IP address. If your machine uses a different interface, you will need to update the script to target the correct interface.
