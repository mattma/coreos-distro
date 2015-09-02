#!/bin/bash
set -e

# Remove the existing VM in the cluster

IP=172.17.8.101 NUM=1 vagrant destroy -f

IP=172.17.8.102 NUM=2 vagrant destroy -f

ROLE=master vagrant destroy -f


# Cleanup the keys, hosts info, and kube config

rm -rf ~/.fleetctl/known_hosts

rm -rf ~/.vagrant.d/insecure_private_key


# private key of kubeconfig
rm -rf ~/.kube/config


# Cleanup the certs folder

./setup/utils/certs-cleanup.sh
