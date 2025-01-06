+++
date = '2025-01-06T08:27:34Z'
draft = false
title = "ECS ENI Trunking"
+++

![ECS ENI Trunking](/ecs-eni-trunking.png)

When a task is started, the Amazon ECS container agent creates an additional pause container for each task before
starting the containers in the task definition. It then configures the network namespace of the pause container by
running the [amazon-ecs-cni-plugins](https://github.com/aws/amazon-ecs-cni-plugins)  CNI plugins. The agent then starts
the rest of the containers in the task so that they share the network stack of the pause container.
This means that all containers in a task are addressable by the IP addresses of the ENI, and they can communicate with
each other over the localhost interface.

[Linux considerations](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking-awsvpc.html#linux)

## EC2 interfaces

- SSM/SSH onto the instance
- view network interfaces - `ip addr` or `ifconfig -a`, we can see (in the above example):
  - `enp39s0` Primary ENI
  - `enp40s0` Trunk ENI (search in AWS console by ENI IP)

## Docker containers

We cannot see any branch ENI. Let's inspect docker containers.

- view docker networks `docker network ls`
- inspect each network
  - `docker network inspect bridge` - no containers, maps to `docker0` network interface
  - `docker network inspect host` - `ecs-agent` container
  - `docker network inspect none` - `task-xyz` pause container

What is the network for `task-xyz` containers?

- list containers `docker ps` and select one of the task containers `docker inspect task-xyz-a`
- we can see `HostConfig.NetworkMode` pointing to pause container.
- also `Config.Hostname` points to branch ENI we were looking for!

## Network

We can see that task containers use [container network](https://docs.docker.com/engine/network/#container-networks)
of `ecs-<task-definition>-internalpause-<hash>` container. But these pause containers use network none. Let's have
a look at traffic on trunk interface:
- `tcpdump -i enp40s0 -ven` (-v verbose, -e print link level header, -n do not resolve IP)
  - we can see on link level line `ethertype 802.1Q (0x8100)` - trunk ENI is using vxlan
  - we can also see traffic is forwarded to branch ENIs

## AWS console

There is currently no way to find branch ENIs attached to trunk without connecting to EC2 instance. Even though there
is a cli command
[`aws ec2 describe-trunk-interface-associations`](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/describe-trunk-interface-associations.html)
it is in 'preview' since and is not available for customers to use
(you get `User <accoun-number> is not permitted to perform this operation`) Even if you use admin user, or have explicit
IAM permissions for this operation.
