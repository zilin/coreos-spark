#!/bin/bash

DNS_IP=$(ip -o -4 addr list docker0 | awk -F" " '{print $4}'| sed -e 's/\/.*$//')
DNS_IP2=8.8.8.8
DNS_SEARCH=docker.local
DNS_PARAM="--dns $DNS_IP --dns $DNS_IP2 --dns-search $DNS_SEARCH"

MASTER_IMAGE="amplab/spark-master:1.0.0"
WORKER_IMAGE="amplab/spark-worker:1.0.0"
SHELL_IMAGE="amplab/spark-shell:1.0.0"
MASTER_NAME="master"
WORKER_NAME="worker"
SHELL_NAME="shell"

DOCKER="sudo docker"
NUM_WORKERS=2

function docker_start() {
  NAME=$1
  IMAGE=$2
  PARAMS=$3
  RUN_PARAMS=$4
  $DOCKER run $RUN_PARAMS -d -h $NAME --name $NAME $DNS_PARAM $IMAGE $PARAMS
  $DOCKER logs -f $NAME
}

function docker_stop() {
  NAME=$1
  $DOCKER stop $NAME && $DOCKER rm $NAME
}

function print_help() {
  echo "Usage: $0 <action> <params>"
  echo ""
  echo "  action: start_master/stop_master/start_worker/stop_worker/start_shell/stop_shell"
  echo "  params: # of workers"
  echo ""
}

if [[ "$1" == "" ]]; then
  print_help
else
  case "$1" in
  start_master)
    docker_start $MASTER_NAME $MASTER_IMAGE
    ;;
  stop_master)
    docker_stop $MASTER_NAME
    ;;
  start_worker)
    MASTER_IP=$($DOCKER inspect -f "{{ .NetworkSettings.IPAddress }}" $MASTER_NAME)
    if [[ "$2" != "" ]]; then
      NUM_WORKERS=$2
    fi 
    for i in `seq 1 $NUM_WORKERS`; do
      docker_start $WORKER_NAME$i $WORKER_IMAGE $MASTER_IP
    done
    ;;
  stop_worker)
    if [[ "$2" != "" ]]; then
      NUM_WORKERS=$2
    fi 
    for i in `seq 1 $NUM_WORKERS`; do
      docker_stop $WORKER_NAME$i
    done
    ;;
  start_shell)
    MASTER_IP=$($DOCKER inspect -f "{{ .NetworkSettings.IPAddress }}" $MASTER_NAME)
    docker_start $SHELL_NAME $SHELL_IMAGE $MASTER_IP "-it"
    ;;
  stop_shell)
    docker_stop $SHELL_NAME
    ;;
  fetch_docker_dns)
    wget https://github.com/zilin/docker-dns/releases/download/v0.0.1/docker-dns
    ;;
  *)
    print_help
    ;;
  esac
fi
