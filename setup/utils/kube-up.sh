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



kubectl get secret --all-namespaces
kubectl delete secret/SECRET_NAME

kubectl get secret --all-namespaces
kubectl describe secret/SECRET_NAME


# Kubernetes nodes

fleetctl start units/flanneld.service units/docker.service units/kube-proxy.service units/kube-kubelet.service
