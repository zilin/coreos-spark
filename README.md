coreos-spark
============

This repository contains a script for running Spark in CoreOS. It was adapted from https://github.com/amplab/docker-scripts.

### Pull Docker Images
First, you need pull a few Docker Images:
```
./spark.sh pull_images
```

### Setup DNS service
Before you start a Spark Cluster, you need setup a DNS service. Here we use https://github.com/zilin/docker-dns instead of dnsmasq to provide DNS inside Docker containers.

#### Fetch Docker-DNS
Run the following command to fetch pre-compiled docker-dns binary from github and install it (and system unit file) to CoreOS:
```
./spark.sh install_docker_dns
```

### Running a Spark cluster
Use the same script, you can start Spark master, workers and shell.

#### Start Spark Master
To start the master, run:
```
./spark.sh start_master
```

#### Start Spark Worker
To start the workers, run:
```
./spark.sh start_worker 3
```
where `3` is the number of workers.

#### Start Spark Shell
```
./spark.sh start_shell
```
Attach to the shell container via this command,
```
sudo docker attach shell
```
If the screen appears to stay blank just hit return to get to the prompt.
#### Execute an example 
```
scala> val textFile = sc.textFile("hdfs://master:9000/user/hdfs/test.txt")
scala> textFile.count()
scala> textFile.map({line => line}).collect()
```
