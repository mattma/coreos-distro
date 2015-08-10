This example demonstrates the usage of Kubernetes to perform a live update on a running group of pods. It is based on [Update-demo](https://github.com/GoogleCloudPlatform/kubernetes/tree/master/docs/user-guide/update-demo)

1. Turn up the UX for the demo. Start the proxy service.

You must use the default `--port 8001` for the following demonstration to work properly

```bash
cd <coreos-distro>
kubectl proxy --www=examples/update-demo/local/ --port=8001 &
# launch at http://localhost:8001/static
```

2. Run the controller

Now we will turn up two replicas of an image. They all serve on internal port 80.

```bash
kubectl create -f examples/update-demo/v1/snail-rc.yaml
kubectl get rc,po -o wide # one replicacontrollers and 2 pods
```

3. Try resizing the controller

```bash
kubectl scale --replicas=4 rc snail
```

4. Update the docker image

`rolling-update` command in kubectl will do 2 things:

- Create a new replication controller with a pod template that uses the new image (gcr.io/google_containers/update-demo:kitten)

- Resize the old and new replication controllers until the new controller replaces the old. This will kill the current pods one at a time, spinnning up new ones to replace them.

```bash
kubectl rolling-update --update-period=10s snail -f examples/update-demo/v1/kitten-rc.yaml
kubectl get rc,po -o wide
```

## Add machines

Add one more machines into the cluster, it will use the same setting with the same unit files, so it will pick up
the `flannel.service`, `kube-kubelet.service`, `kube-proxy.service` automatically. Join the same kubernetes cluster.

```bash
# Add one more worker nodes into the cluster
IP=172.17.8.103 NUM=3 vagrant up
# will show three machines in the cluster
fleetctl list-machines
# will show three machines in the cluster
kubectl get nodes
```

Scale replica with more pods, Pods will be placed onto the available new/old machines

```bash
kubectl scale rc kitten --replicas=10
kubectl get pods
```

Remove a machine from the cluster, Pods will be recreated on the available machines

```bash
# remove a machine
IP=172.17.8.103 NUM=3 vagrant destroy -f
# will take a minute to see machines is offline
fleetctl list-machines

# will see `172.17.8.103` node becomes `NotReady` status
kubectl get nodes

# api server take a couple of minutes to discovery the lost the worker nodes
# you could see the demo worker nodes will rebuild, relaunch a container in a healthy node
kubectl delete nodes 172.17.8.103
```

5. Bring down the pods

This will first 'stop' the replication controller by turning the target number of replicas to 0. It'll then delete that controller.

```bash
kubectl stop rc kitten
```

6. Cleanup

```bash
ps # get the PID number for the running kubectl cmd
kill <PID>
vagrant destroy -f
```

- Updating the Docker images

If you want to build your own docker images, you can set `$DOCKER_HUB_USER` to your Docker user id and run the included shell script. It can take a few minutes to download/upload stuff.

```bash
export DOCKER_HUB_USER=my-docker-id
./examples/update-demo/build-images.sh
```

To use your custom docker image in the above examples, you will need to change the image name in `examples/update-demo/v1/nautilus-rc.yaml` and `examples/update-demo/v1/kitten-rc.yaml`.

- [kubernetes/test-webserver](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/contrib/for-demos/test-webserver/test-webserver.go)

A tiny web server that serves a static file.

Demo:

- without login the host, schedule the container, and launch/maintain the application lifecycle.

```bash
kubectl proxy --www=examples/update-demo/local --port=8001 &

cd examples/update-demo/v1

kubectl get rc,po

kubectl create -f snail-rc.yaml

kubectl scale rc snail --replicas=4

kubectl describe pods <POD_ID>

kubectl describe rc snail

kubectl delete pods <POD_ID>

kubectl rolling-update --update-period=10s snail -f examples/update-demo/v1/kitten-rc.yaml

kubectl delete nodes <associated machines>
kubectl delete pods <associated pods>

kubectl get nodes  # new pods will be recreated in a healthy node

# Tear down the cluster
kubectl stop rc snail
kill <PS_PID>
vagrant destroy -f
```

- `kubectl delete pods <pod_id>`, simulate a server failure
- docker run to create a new container, then it would be killed

- replicas to create more containers.
- add more machines resources, automatically rebound the containers.

- can go back to the previous version
