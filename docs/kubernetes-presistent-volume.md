## [How To Use Persistent Volumes](https://github.com/kubernetes/kubernetes/tree/master/docs/user-guide/persistent-volumes)

A Persistent Volume (PV) in Kubernetes represents a real piece of underlying storage capacity in the infrastructure. Cluster administrators must first create storage disks in order for Kubernetes to mount it.

Note: For `HostPath` to work, you will need to run a single node cluster.

### Background knowledge: [Persistent Storage](https://github.com/kubernetes/kubernetes/blob/master/docs/design/persistent-storage.md)

- `PersistentVolume` (PV)

It is a storage resource provisioned by an administrator. It is analogous to a node.

- `PersistentVolumeClaim` (PVC)

It is a user's request for a persistent volume to use in a pod. It is analogous to a pod.

** How it works **

- system component

`PersistentVolumeClaimBinder` is a singleton running in master that watches all `PersistentVolumeClaims` in the system and binds them to the closest matching available `PersistentVolume`. The volume manager watches the API for newly created volumes to manage.

- volume:

`PersistentVolumeClaimVolumeSource` references the user's PVC in the same namespace. This volume finds the bound `PV` and mounts that volume for the pod. A `PersistentVolumeClaimVolumeSource` is, essentially, a wrapper around another type of volume that is owned by someone else (the system).

### Get Started

1. PVs are created by posting them to the API server.

```bash
kubectl create -f persistent-volumes/volumes/local-01.yaml
# show the list of Persistent Volume
kubectl get pv
```

```yaml
# persistent-volumes/volumes/local-01.yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  name: pv0001
  labels:
    type: local
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/tmp/data01"

  # persistentVolumeReclaimPolicy: Recycle
```

```yaml
# NFS example
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0003
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  nfs:
    path: /tmp
    server: 172.17.0.2
```

2. Requesting storage

Users of Kubernetes request persistent storage for their pods. Users claim to storage and can manage its lifecycle independently from the many pods that may use it. Claims must be created in the same namespace as the pods that use them.

```bash
kubectl create -f persistent-volumes/claims/claim-01.yaml
# show the list of Persistent Volume Claims
kubectl get pvc
```

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: myclaim-1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```

3. Using your claim as a volume

Claims are used as volumes in pods. Kubernetes uses the claim to look up its bound PV. The PV is then exposed to the pod.

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: mypod
  labels:
    name: frontendhttp
spec:
  # to make sure it will always deploy on the same node when crashes
  nodeName: <MACHINE_NODE_IP>
  containers:
    - name: myfrontend
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
      - mountPath: "/var/www/html"
        name: mypd
  volumes:
    - name: mypd
      persistentVolumeClaim:
       claimName: myclaim-1
```

### Clean Up

Releasing a claim and Recycling a volume

```bash
# When a claim holder is finished with their data, they can delete their claim.
kubectl delete pvc myclaim-1
```

The `PersistentVolumeClaimBinder` will reconcile this by removing the claim reference from the `PV` and change the `PV`s status to 'Released'. Admins can script the recycling of released volumes. Future dynamic provisioners will understand how a volume should be recycled.
