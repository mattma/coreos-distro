#!/bin/bash
set -e

CLUSTER_NAME=kube-rocks
CA_CERT=./setup/tmp/kubernetes/ca.crt
MASTER_IP=https://172.17.8.100:443
USER=mattma
CLI_CERT=./setup/tmp/kubernetes/kubecfg.cert
CLI_KEY=./setup/tmp/kubernetes/kubecfg.key
CONTEXT_NAME=rocks

# setup the cluster
kubectl config set-cluster $CLUSTER_NAME --certificate-authority=$CA_CERT --embed-certs=true --server=$MASTER_IP

# setup user credentials
kubectl config set-credentials $USER --client-certificate=$CLI_CERT --client-key=$CLI_KEY --embed-certs=true

# setup the context for the user and cluster
kubectl config set-context $CONTEXT_NAME --cluster=$CLUSTER_NAME --user=$USER

# use the context
kubectl config use-context $CONTEXT_NAME

# show up the completed config
kubectl config view
