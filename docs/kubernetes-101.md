## Design

### Definition

A replication controller combines a template for pod creation (a "cookie-cutter" if you will) and a number of desired replicas, into a single Kubernetes object. The replication controller also contains a label selector that identifies the set of objects managed by the replication controller. The replication controller constantly measures the size of this set relative to the desired size, and takes action by creating or deleting pods.

Kubernetes Labels are key-value pairs that are attached to each object in Kubernetes. Label selectors can be passed along with a RESTful list request to the apiserver to retrieve a list of objects which match that label selector.

```yaml
apiVersion: v1
kind: ReplicationController
# To add a label, add a labels section under metadata.used for selectors
metadata:
  name: redis
  labels:
    name: redis-master
spec:
  replicas: 1
  # selector identifies the set of Pods that this replication controller is responsible for managing
  selector:
    name: redis-master
  # podTemplate defines the 'cookie cutter' used for creating new pods when necessary
  template:
    metadata:
      # Important: these labels need to match the selector above
      # The api server enforces this constraint.
      labels:
        name: redis-master
    spec:
      # indicates that we just want to run the container once and then terminate the pod.
      restartPolicy: Never
      containers:
      # name of the pod resource created, and must be unique within the cluster
      - name: redis
        image: redis

        # Running `command` for this container
        # command: ["mongod","--storageEngine=wiredTiger"]
        # used for override the arguments inside `Entrypoint`
        # args: ["--storageEngine=wiredTiger"]
        #
        # Another form of command
        # command:
        #    - sleep
        #    - "3600"

        # expand environment variables
        env:
        - name: MESSAGE
          value: "hello world"
        - name: HEAP_NEWSIZE
          value: 100M

        volumeMounts:
        # Mount Name: a reference to a specific empty dir volume, name must match the volume name below
        # Mount Path: a path to mount the empty dir volume within the container
        # ReadOnly: Container redis doesn't need to write to the directory, most used to share with another container with volume
        - name: redis-persistent-storage
          mountPath: /data/redis
          # readOnly: true
      # [Volume Types](http://kubernetes.io/v1.0/docs/user-guide/volumes.html)
      volumes:
        - name: mongo-persistent-storage
        # EmptyDir: Creates a new directory that will persist across container failures and restarts.
        # HostPath: Mounts an existing directory on the node's file system (e.g. /var/logs).
          emptyDir: {}

      - name: nginx
        image: nginx
        # defines the health checking
        livenessProbe:
          # an http probe
          httpGet:
            path: /_status/healthz
            port: 80
          # length of time to wait for a pod to initialize
          # after pod startup, before applying health checking
          initialDelaySeconds: 30
          timeoutSeconds: 1
        ports:
        - containerPort: 80
```

A [service](http://kubernetes.io/v1.0/docs/user-guide/services.html) provides a way to refer to a set of pods (selected by labels) with a single static IP address. It may also provide load balancing, if supported by the provider.

When created, each service is assigned a unique IP address. This address is tied to the lifespan of the Service, and will not change while the Service is alive. Pods can be configured to talk to the service, and know that communication to the service will be automatically load-balanced out to some pod that is a member of the set identified by the label selector in the Service.

a Service is backed by a group of pods. These pods are exposed through endpoints. The Service's selector will be evaluated continuously and the results will be POSTed to an Endpoints object

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  # All pods to see the nginx apparently running on :80. A service can map an incoming port to any targetPort in the backend pod.
  # Once created, the service proxy on each node is configured to set up a proxy on the specified port (in this case port 8000).
  # Traffic will be forwarded from the service "port" (on the service node) to the targetPort on the pod that the service listens to.
  ports:
  - port: 8000 # the port that this service should serve on
    # the container on each pod to connect to, can be a name
    # (e.g. 'www') or a number (e.g. 80)
    targetPort: 80
    # This specification will create a Service which targets TCP port 80 on any Pod with the app=nginx label, and expose it on an abstracted Service port (targetPort: is the port the container accepts traffic on, port: is the abstracted Service port, which can be any port other pods use to access the Service)
    protocol: TCP
  # just like the selector in the replication controller,
  # but this time it identifies the set of pods to load balance traffic to.
  selector:
    app: nginx
  # http://kubernetes.io/v1.0/docs/user-guide/services.html#external-services
  # If you set the type field to "NodePort", the Kubernetes master will allocate a port from a flag-configured range (default: 30000-32767), and each node will proxy that port (the same port number on every node) into your Service. That port will be reported in your Service's spec.ports[*].nodePort field.
  type: NodePort
```

## Status

### Check the current pod is running

```bash
# List all pods
kubectl get po -o wide

# Test the pod is working by creating a busybox pod
# and exec commands on it remotely
# syntax: kubectl exec POD -c CONTAINER -- COMMAND [args...]
# http://kubernetes.io/v1.0/docs/user-guide/kubectl/kubectl_exec.html


# the pod IPs are not externally accessible
# access its http endpoint with curl on port 80
curl http://$(kubectl get pod nginx -o=template -t={{.status.podIP}})

# check the service is working
export SERVICE_IP=$(kubectl get service mongo -o=template -t={{.spec.clusterIP}})
export SERVICE_PORT=$(kubectl get service mongo -o=template '-t={{(index .spec.ports 0).port}}')
curl http://${SERVICE_IP}:${SERVICE_PORT}

# find the public IP address assigned to your application
kubectl get svc SERVICE_NAME -o json | grep \"ip\"

# Print envirment variable
kubectl exec <pod_name> -- printenv | grep KUBERNETES
```

### Check with labels

```bash
# List all pods with the label redis-master
kubectl get po -l name=redis-master

# the pod template’s labels are used to create a selector that will match pods carrying those labels
# see this field by requesting it
kubectl get rc ts-server -o template --template="{{.spec.selector}}"

# Check the nodes the pod is running on
kubectl get po -l name=ts-server -o wide
# Check your pods ips:
kubectl get po -l name=ts-server -o json | grep podIP
# You should be able to ssh into any node in your cluster and curl both ips. Note that the containers are not using port 80 on the node, nor are there any special NAT rules to route traffic to the pod. This means you can run multiple nginx pods on the same node all using the same containerPort and access them from any other pod or node in your cluster using ip. Like Docker, ports can still be published to the host node's interface(s), but the need for this is radically diminished because of the networking model.
```

### Access the service

Kubernetes offers a DNS cluster addon Service that uses skydns to automatically assign dns names to other Services. You can check if it’s running on your cluster:

```bash
kubectl get services kube-dns

kubectl exec <pod_name> -- nslookup <service_name>
```

### Process Health Checking

The Kubelet constantly asks the Docker daemon if the container process is still running, and if not, the container process is restarted. In all of the Kubernetes examples you have run so far, this health checking was actually already enabled. It's on for every single container that runs in Kubernetes.

These checks are performed by the Kubelet to ensure that your application is operating correctly for a definition of "correctly" that you provide.

Currently, there are three types of application health checks that you can choose from:

- HTTP Health Checks - The Kubelet will call a web hook. If it returns between 200 and 399, it is considered success, failure otherwise. See health check examples [here](http://kubernetes.io/v1.0/docs/user-guide/liveness/).

- Container Exec - The Kubelet will execute a command inside your container. If it exits with status 0 it will be considered a success. See health check examples [here](http://kubernetes.io/v1.0/docs/user-guide/liveness/).

- TCP Socket - The Kubelet will attempt to open a socket to your container. If it can establish a connection, the container is considered healthy, if it can't it is considered a failure.


### Debugging the system

- Check the health

```bash
# get information about a pod, including the machine that it is running on
kubectl describe pods/kube-dns-bimoo

kubectl describe nodes/172.17.8.101
```

- Check the secret key has been placed

```bash
# list all secret keys
kubectl get secret

# describe the secret key by its name, name defined by secret file name field
kubectl describe secret myregisterkey
```

- view the container logs for a given pod, These logs will usually give you enough information to troubleshoot.
However, if you should want to SSH to the listed host machine, you can inspect various logs there directly as well.

```bash
kubectl logs <pod_name>
```

### Cleanup

```bash
# Stop all running pods controlled by this replication controller
kubectl stop rc my-nginx

# Delete all running pods controlled by this replication controller and itself
kubectl delete rc my-nginx

# Leave all running pods controlled by this replication controller running
# and ONLY delete replication controller itself
kubectl delete rc my-nginx --cascade=false
```
