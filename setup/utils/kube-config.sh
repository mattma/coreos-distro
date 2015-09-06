#!/bin/bash
set -e

CLUSTER_NAME=kube-rocks
CA_CERT=./setup/tmp/kubernetes/ca.crt
MASTER_IP=https://172.17.8.100:6443
USER=mattma
CLI_CERT=./setup/tmp/kubernetes/server.cert
CLI_KEY=./setup/tmp/kubernetes/server.key
TOKEN=O5PEhSll0GJBhpeEUMSZJXPjIhr0zscH
CONTEXT_NAME=rocks

# setup the cluster
kubectl config set-cluster $CLUSTER_NAME --certificate-authority=$CA_CERT --embed-certs=true --server=$MASTER_IP

# setup user credentials
kubectl config set-credentials $USER --token=$TOKEN

# setup the context for the user and cluster
kubectl config set-context $CONTEXT_NAME --cluster=$CLUSTER_NAME --user=$USER --namespace=default

# use the context
kubectl config use-context $CONTEXT_NAME

# show up the completed config
kubectl config view
