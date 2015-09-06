# [DNS](https://github.com/kubernetes/kubernetes/blob/release-1.0/docs/user-guide/connecting-applications.md#dns)

Kubernetes offers a DNS cluster addon Service that uses skydns to automatically assign dns names to other Services.

```bash
# check if it is running on your cluster
kubectl get services kube-dns
```

## Enable your DNS service

Add the required logic to read some config variables and plumb them all the way down to kubelet. Each kubelet needs to run with the following flags set:

```yaml
# enables DNS with a DNS Service IP of 10.0.0.10 and a local domain of cluster.local
--cluster_dns=10.0.0.10 # <DNS service ip>
--cluster_domain=cluster.local  # <default local domain>
```

Then start the DNS server ReplicationController and Service, instantiated with `kubectl create`.

## Test if it is working

```bash
# step 1
kubectl create -f example/dns/busybox.yaml

# step 2: Wait for this pod to go into the running state
kubectl get pods busybox

# step 3: Validate DNS works
kubectl exec busybox -- nslookup kubernetes

# Should see the output like below. If you see that, DNS is working correctly.
Server:    10.0.0.10
Address 1: 10.0.0.10

Name:      kubernetes
Address 1: 10.0.0.1
```

## How does it work?

The DNS server itself runs as a Kubernetes Service. This gives it a stable IP address. When you run the SkyDNS service, you want to assign a static IP to use for the Service. For example, if you assign the DNS Service IP as 10.0.0.10, you can configure your kubelet to pass that on to each container as a DNS server.

Of course, giving services a name is just half of the problem - DNS names need a domain also. This implementation uses a configurable local domain, which can also be passed to containers by kubelet as a DNS search suffix.

SkyDNS depends on etcd for what to serve, currently, run etcd and SkyDNS together in a pod, and we do not try to link etcd instances across replicas, A helper container called `kube2sky` also runs in the pod and acts a bridge between Kubernetes and SkyDNS. It finds the Kubernetes master through the kubernetes service (via environment variables), pulls service info from the master, and writes that to etcd for SkyDNS to find.

When running a pod, kubelet will prepend the cluster DNS server and search paths to the node's own DNS settings.


## Service account

Service-account private key file generation

```bash
openssl genrsa -out kube-serviceaccount.key 2048 2>/dev/null
```
