# [Core Concept](https://github.com/kubernetes/kubernetes/blob/968cbbee5d4964bd916ba379904c469abb53d623/docs/getting-started-guides/scratch.md#designing-and-preparing)

### Cloud Provider

It is a module which provides an interface for managing TCP Load Balancers, Nodes (Instances) and Networking Routes. It is possible to create a custom cluster without implementing a cloud provider (for example if using bare-metal), and not all parts of the interface need to be implemented, depending on how flags are set on various components.

### Network

Kubernetes allocates an IP address to each pod. When creating a cluster, you need to allocate a block of IPs for Kubernetes to use as Pod IPs. The simplest approach is to allocate a different block of IPs to each node in the cluster as the node is added. A process in one pod should be able to communicate with another pod using the IP of the second pod.

You need to select an address range for the Pod IPs. Allocate one CIDR subnet for each node's PodIPs, or a single large CIDR from which smaller CIDRs are automatically allocated to each node (if nodes are dynamically added).

- You need max-pods-per-node * max-number-of-nodes IPs in total. A /24 per node supports 254 pods per machine and is a common choice. If IPs are scarce, a /26 (62 pods per machine) or even a /27 (30 pods) may be sufficient.

- e.g. use 10.10.0.0/16 as the range for the cluster, with up to 256 nodes using 10.10.0.0/24 through 10.10.255.0/24, respectively.

- Need to make these routable or connect with overlay.

Kubernetes also allocates an IP to each service. However, service IPs do not necessarily need to be routable. The kube-proxy takes care of translating Service IPs to Pod IPs before traffic leaves the node. You do need to Allocate a block of IPs for services. Call this `SERVICE_CLUSTER_IP_RANGE`.

- e.g. you could set SERVICE_CLUSTER_IP_RANGE="10.0.0.0/16", allowing 65534 distinct services to be active at once. Note that you can grow the end of this range, but you cannot move it without disrupting the services and pods that already use it.

Need to pick a static IP for master node `MASTER_IP`, 1. Open any firewalls to allow access to the apiserver ports 80 and/or 443.
2. Enable ipv4 forwarding sysctl, `net.ipv4.ip_forward = 1`
