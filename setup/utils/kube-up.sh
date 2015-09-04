#!/bin/bash

# Show the current fleet planes and etcd status

fleetctl list-machines

fleetctl list-units

etcdctl member list

etcdctl cluster-health

# Kubernetes control plane

fleetctl start units/kube-apiserver.service

fleetctl start units/kube-controller-manager.service

fleetctl start units/kube-scheduler.service


# Kubernetes nodes

fleetctl start units/flanneld.service

fleetctl start units/docker.service

fleetctl start units/kube-proxy.service

fleetctl start units/kube-kubelet.service
