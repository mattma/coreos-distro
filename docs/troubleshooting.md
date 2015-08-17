## [TroubleShooting](https://github.com/kubernetes/kubernetes/blob/release-1.0/docs/user-guide/application-troubleshooting.md#debugging-pods)

### Debugging Pods

Check the current state of the Pod and recent events, look at the state of the containers in the pod.  Are they all `Running`?  Have there been recent restarts?

```console
kubectl describe pods ${POD_NAME}
```

- pending

If a Pod is stuck in `Pending` it means that it can not be scheduled onto a node.  Generally this is because
there are insufficient resources of one type or another that prevent scheduling.  Look at the output of the
`kubectl describe ...` command above.  There should be messages from the scheduler about why it can not schedule
your pod.  Reasons include:

* **You don't have enough resources**:  You may have exhausted the supply of CPU or Memory in your cluster, in this case
you need to delete Pods, adjust resource requests, or add new nodes to your cluster. See [Compute Resources document](compute-resources.md#my-pods-are-pending-with-event-message-failedscheduling) for more information.

* **You are using `hostPort`**:  When you bind a Pod to a `hostPort` there are a limited number of places that pod can be
scheduled.  In most cases, `hostPort` is unnecessary, try using a Service object to expose your Pod.  If you do require
`hostPort` then you can only schedule as many Pods as there are nodes in your Kubernetes cluster.

- waiting
-
The most common cause of `Waiting` pods is a failure to pull the image.  There are three things to check:

* Make sure that you have the name of the image correct
* Have you pushed the image to the repository?
* Run a manual `docker pull <image>` on your machine to see if the image can be pulled.

### Debugging Replication Controllers

Replication controllers are fairly straightforward.  They can either create Pods or they can't.  If they can't
create pods, then please refer to the [instructions above](#debugging-pods) to debug your pods.

You can also use `kubectl describe rc ${CONTROLLER_NAME}` to introspect events related to the replication
controller.

### Debugging Services

Services provide load balancing across a set of pods.  There are several common problems that can make Services
not work properly.  The following instructions should help debug Service problems.

First, verify that there are endpoints for the service. For every Service object, the apiserver makes an `endpoints` resource available.

You can view this resource with:

```console
$ kubectl get endpoints ${SERVICE_NAME}
```

Make sure that the endpoints match up with the number of containers that you expect to be a member of your service.
For example, if your Service is for an nginx container with 3 replicas, you would expect to see three different
IP addresses in the Service's endpoints.

#### My service is missing endpoints

If you are missing endpoints, try listing pods using the labels that Service uses.  Imagine that you have
a Service where the labels are:

```yaml
...
spec:
  - selector:
     name: nginx
     type: frontend
```

You can use:

```console
$ kubectl get pods --selector=name=nginx,type=frontend
```

to list pods that match this selector.  Verify that the list matches the Pods that you expect to provide your Service.

If the list of pods matches expectations, but your endpoints are still empty, it's possible that you don't
have the right ports exposed.  If your service has a `containerPort` specified, but the Pods that are
selected don't have that port listed, then they won't be added to the endpoints list.

Verify that the pod's `containerPort` matches up with the Service's `containerPort`

#### Network traffic is not forwarded

If you can connect to the service, but the connection is immediately dropped, and there are endpoints
in the endpoints list, it's likely that the proxy can't contact your pods.

There are three things to
check:
   * Are your pods working correctly?  Look for restart count, and [debug pods](#debugging-pods)
   * Can you connect to your pods directly?  Get the IP address for the Pod, and try to connect directly to that IP
   * Is your application serving on the port that you configured?  Kubernetes doesn't do port remapping, so if your application serves on 8080, the `containerPort` field needs to be 8080.
