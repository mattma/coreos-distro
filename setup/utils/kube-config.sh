#!/bin/bash
set -e

CLUSTER_NAME=kube-rocks
CA_CERT=./setup/tmp/kubernetes/ca.crt
MASTER_IP=https://172.17.8.100:6443
USER=admin
CLI_CERT=./setup/tmp/kubernetes/kubecfg.cert
CLI_KEY=./setup/tmp/kubernetes/kubecfg.key
CONTEXT_NAME=rocks

# setup the cluster
kubectl config set-cluster $CLUSTER_NAME --certificate-authority=$CA_CERT --embed-certs=true --server=$MASTER_IP

# setup user credentials
kubectl config set-credentials $USER --certificate-authority=$CA_CERT --client-certificate=$CLI_CERT --client-key=$CLI_KEY --embed-certs=true

# setup the context for the user and cluster
kubectl config set-context $CLUSTER_NAME --cluster=$CLUSTER_NAME --user=$USER

# use the context
kubectl config use-context $CLUSTER_NAME

# show up the completed config
kubectl config view
