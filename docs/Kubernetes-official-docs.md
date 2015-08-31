# Kubernetes

Kubernetes provides mechanisms for application deployment, scheduling, updating, maintenance, and scaling. A key feature of Kubernetes is that it actively manages the containers to ensure that the state of the cluster continually matches the user's intentions.

Every resource in Kubernetes, such as a pod, is identified by a URI and has a UID. Important components of the URI are the kind of object (e.g. pod), the object’s name, and the object’s namespace. For a certain object kind, every name is unique within its namespace. In contexts where an object name is provided without a namespace, it is assumed to be in the default namespace. UID is unique across time and space.

## Control Plane

A set of components work together to provide a unified view of the cluster.

1. API Server

The apiserver serves up the Kubernetes API. It is intended to be a CRUD-y server, with most/all business logic implemented in separate components or in plug-ins. It mainly processes REST operations, validates them, and updates the corresponding objects in etcd (and eventually other stores).

2. Scheduler

The scheduler is pluggable and binds unscheduled pods to nodes via the /binding API.

3. Controller Manager Server

All other cluster-level functions are currently performed by the Controller Manager, it is layered on top of the simple pod API. For instance, Endpoints objects are created and updated by the endpoints controller, and nodes are discovered, managed, and monitored by the node controller.

4. Etcd

All persistent master state is stored in an instance of etcd which store configuration data reliably. With watch support, coordinating components can be notified very quickly of changes.

## Node

The Kubernetes node has the services necessary to run application containers and be managed from the master systems.

1. Kubelet

The Kubelet manages pods and their containers, their images, their volumes, etc.

2. Kube-Proxy

Each node also runs a simple network proxy and load balance. services as defined in the Kubernetes API on each node and can do simple TCP and UDP stream forwarding (round robin) across a set of backends.

Service endpoints are currently found via DNS or through environment variables (both Docker-links-compatible and Kubernetes
**{FOO}_SERVICE_HOST** and **{FOO}_SERVICE_PORT** variables are supported). These variables resolve to ports managed by the service proxy.

3. Docker

Each node runs Docker, which takes care of the details of downloading images and running containers.

## Pods

pods are the smallest deployable units that can be created, scheduled, and managed. A pod corresponds to a colocated group of applications running with a shared context. Within that context, the applications may also have individual cgroup isolations applied. A pod models an application-specific "logical host" in a containerized environment. It may contain one or more applications which are relatively tightly coupled — in a pre-container world, they would have executed on the same physical or virtual host.


