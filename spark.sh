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
MASTER_HOST_PORT="8080"

DOCKER="sudo docker"
NUM_WORKERS=2
DOCKER_DNS_DIR=/opt/docker-dns

function docker_start() {
  NAME=$1
  IMAGE=$2
  PARAMS=$3
  RUN_PARAMS=$4
  $DOCKER run $RUN_PARAMS -d -h $NAME --name $NAME $DNS_PARAM $IMAGE $PARAMS
}

function docker_stop() {
  NAME=$1
  $DOCKER stop $NAME && $DOCKER rm $NAME
}

function docker_wait() {
  NAME=$1
  QUERY_STRING=$2
  $DOCKER logs $NAME | grep "$QUERY_STRING"
}

function install_docker_dns {
  sudo mkdir -p $DOCKER_DNS_DIR && sudo chown -R core: $DOCKER_DNS_DIR
  sudo mv $1 $DOCKER_DNS_DIR && sudo chmod +x $DOCKER_DNS_DIR/$1
  sudo tee /etc/systemd/system/docker-dns.service > /dev/null << EOF
[Unit]
Description=Simple Docker DNS Server
ConditionFileIsExecutable=$DOCKER_DNS_DIR/docker-dns
After=docker.service
Requires=docker.service

[Service]
ExecStart=$DOCKER_DNS_DIR/docker-dns
Restart=on-failure
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl start docker-dns
}

function print_help() {
  echo "Usage: $0 <action> <params>"
  echo ""
  echo "  action: pull_images,"
  echo "          start_master,stop_master,"
  echo "          start_worker,stop_worker,"
  echo "          start_shell,stop_shell,"
  echo "          install_docker_dns"
  echo "  params: # of workers"
  echo ""
}

if [[ "$1" == "" ]]; then
  print_help
else
  case "$1" in
  pull_images)
    $DOCKER pull $MASTER_IMAGE
    $DOCKER pull $WORKER_IMAGE
    $DOCKER pull $SHELL_IMAGE
    ;;
  start_master)
    docker_start $MASTER_NAME $MASTER_IMAGE "" "-p $MASTER_HOST_PORT:8080"
    docker_wait $MASTER_NAME "MasterWebUI: Started MasterWebUI"
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
      docker_wait $WORKER_NAME$i "Worker: Successfully registered with master"
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
    docker_wait $SHELL_NAME "SparkUI: Started SparkUI"
    ;;
  stop_shell)
    docker_stop $SHELL_NAME
    ;;
  install_docker_dns)
    wget https://github.com/zilin/docker-dns/releases/download/v0.0.1/docker-dns
    install_docker_dns ./docker-dns
    ;;
  *)
    print_help
    ;;
  esac
fi
