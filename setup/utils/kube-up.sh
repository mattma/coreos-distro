#!/bin/bash

# Kubernetes control plane

fleetctl start units/kube-apiserver.service

fleetctl start units/kube-controller-manager.service

fleetctl start units/kube-scheduler.service


# Kubernetes nodes

fleetctl start units/flanneld.service

fleetctl start units/docker.service

fleetctl start units/kube-proxy.service

fleetctl start units/kube-kubelet.service


# Start dns service. SkyDns controller and service
kubectl create -f setup/dns/dns-controller.yaml
kubectl create -f setup/dns/dns-service.yaml


# check the cluster info
kubectl cluster-info
