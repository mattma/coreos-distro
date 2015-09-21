#!/bin/bash
set -e

CLUSTER_NAME=kube-rocks
CA_CERT=./setup/tmp/kubernetes/ca.crt
MASTER_IP=https://172.17.8.100:6443
CLI_CERT=./setup/tmp/kubernetes/kubecfg.cert
CLI_KEY=./setup/tmp/kubernetes/kubecfg.key
KUBELET_CERT=./setup/tmp/kubernetes/kubelet.cert
KUBELET_KEY=./setup/tmp/kubernetes/kubelet.key
KUBE_PROXY_CERT=
KUBE_PROXY_KEY=
CONTEXT_NAME=rocks

# setup the cluster
kubectl config set-cluster $CLUSTER_NAME --certificate-authority=$CA_CERT --embed-certs=true --server=$MASTER_IP

echo ''
# setup user credentials
if [ -n "$1" ] && [ $1 = 'KUBELET' ]
then
  echo 'Setup KUBELET config'
  USER=kubelet
  kubectl config set-credentials $USER --certificate-authority=$CA_CERT --client-certificate=$KUBELET_CERT --client-key=$KUBELET_KEY --embed-certs=true

elif [ -n "$1" ] && [ $1 = 'KUBE_PROXY' ]
then
  echo 'Setup KUBE_PROXY config'
  USER=kube-proxy
  kubectl config set-credentials $USER --certificate-authority=$CA_CERT --client-certificate=$KUBE_PROXY_CERT --client-key=$KUBE_PROXY_KEY --embed-certs=true

else
  echo 'Setup CLI config'
  USER=kube-admin
  kubectl config set-credentials $USER --certificate-authority=$CA_CERT --client-certificate=$CLI_CERT --client-key=$CLI_KEY --embed-certs=true
fi
echo ''

# setup the context for the user and cluster
kubectl config set-context $CLUSTER_NAME --cluster=$CLUSTER_NAME --user=$USER

# use the context
kubectl config use-context $CLUSTER_NAME

# show up the completed config
kubectl config view
