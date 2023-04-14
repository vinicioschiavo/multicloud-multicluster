#!/bin/bash
curl https://releases.rancher.com/install-docker/19.03.sh | sh
apt install -y open-iscsi
docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run  rancher/rancher-agent:v2.7.1 --server https://44.200.139.173 --token wbkd8j9k449jvwhmxnr7bg5jw9xqn2kls2kfhbvgpqlhgtj2xt9wcb --ca-checksum 846c311574b6ecdbbdf6d7e87c5918bc5dbaa459fc09b54b736112f50f58bb01 --etcd --controlplane --worker