#!/bin/bash
set -e

IP=172.17.8.100
PLATFORM="darwin"
ETCD_VERSION=2.1.1
FLEET_VERSION=0.11.2
KUBERNETES_VERSION=1.0.4

# etcdctl binary installation
if [ ! -f /usr/local/bin/etcdctl ]; then
  curl -L https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-${PLATFORM}-amd64.zip -o etcd-v${ETCD_VERSION}-${PLATFORM}-amd64.zip
  # unpack the etcd release folder
  unzip etcd-v${ETCD_VERSION}-${PLATFORM}-amd64.zip
  # move `etcdctl` binary into the `/usr/local/bin`
  mv ./etcd-v${ETCD_VERSION}-${PLATFORM}-amd64/etcdctl /usr/local/bin/etcdctl
  # clean up and remove zip folder and unzipped folder
  rm -rf etcd-v${ETCD_VERSION}-${PLATFORM}-amd64.zip etcd-v${ETCD_VERSION}-${PLATFORM}-amd64
fi

# fleetctl binary installation
if [ ! -f /usr/local/bin/fleetctl ]; then
  curl -L https://github.com/coreos/fleet/releases/download/v${FLEET_VERSION}/fleet-v${FLEET_VERSION}-${PLATFORM}-amd64.zip -o fleet-v${FLEET_VERSION}-${PLATFORM}-amd64.zip

  # unpack the fleet release folder
  unzip fleet-v${FLEET_VERSION}-${PLATFORM}-amd64.zip
  # move `fleetctl` binary into the `/usr/local/bin`
  mv ./fleet-v${FLEET_VERSION}-${PLATFORM}-amd64/fleetctl /usr/local/bin/fleetctl
  # clean up and remove zip folder and unzipped folder
  rm -rf fleet-v${FLEET_VERSION}-${PLATFORM}-amd64.zip fleet-v${FLEET_VERSION}-${PLATFORM}-amd64
fi

# kubectl binary installation
if [ ! -f /usr/local/bin/kubectl ]; then
  wget -q --no-check-certificate -L -O /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/${PLATFORM}/amd64/kubectl"
  # make `kubectl` binary executable
  chmod +x /usr/local/bin/kubectl
fi

### Copy and paste those environment variables into shell
echo ""
echo "######## Copy and paste environment variables"
echo ""

echo "### One-Liner"
echo "ssh-add  ~/.vagrant.d/insecure_private_key && export FLEETCTL_TUNNEL=$IP && export ETCDCTL_PEERS=http://$IP:4001 && export KUBERNETES_MASTER=https://$IP:6443"
echo "########"

echo ""
echo "### TL;DR"
echo "ssh-add  ~/.vagrant.d/insecure_private_key"
echo ""

echo "export FLEETCTL_TUNNEL=$IP"
echo ""

echo "export ETCDCTL_PEERS=http://$IP:4001"
echo ""

echo "export KUBERNETES_MASTER=https://$IP:6443"
echo ""

echo "########"
echo ""
