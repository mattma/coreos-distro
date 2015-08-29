[ServiceAccount](https://github.com/kubernetes/kubernetes/blob/21a14eccf2ee2244d687653cad91b8f99f56a426/docs/user-guide/service-accounts.md)

A service account provides an identity for processes that run in a Pod. When you (a human) access the cluster (e.g. using kubectl), you are authenticated by the apiserver as a particular User Account (currently this is usually admin, unless your cluster administrator has customized your cluster). Processes in containers inside pods can also contact the apiserver. When they do, they are authenticated as a particular Service Account (e.g. default). Service accounts are namespaced.

```bash
# List `serviceAccount` resources
kubectl get serviceAccounts

# delete service account name `build-robot`
kubectl delete serviceaccount/build-robot
```

## Kubernetes Service-Account key file (ONLY development)

`kube-serviceaccount.key` file has been generated for the sake of simplicity of deployment. If you want to generate your own, run:

`openssl genrsa -out kube-serviceaccount.key 2048 2>/dev/null`

## Using the Default Service Account to access the API server.

When you create a pod, you do not need to specify a service account. It is automatically assigned the default service account of the same namespace. If you get the raw json or yaml for a pod you have created (e.g. kubectl get pods/podname -o yaml), you can see the spec.serviceAccount field has been automatically set.

Note that if a pod does not have a ServiceAccount set, the ServiceAccount will be set to default.

## Using Multiple Service Accounts

Every namespace has a default service account resource called default.

To use a non-default service account, simply set the `spec.serviceAccount` field of a pod to the name of the service account you wish to use. The service account has to exist at the time the pod is created, or it will be rejected. You cannot update the service account of an already created pod.

## [Manually create a service account API token](https://github.com/kubernetes/kubernetes/blob/21a14eccf2ee2244d687653cad91b8f99f56a426/docs/user-guide/service-accounts.md#manually-create-a-service-account-api-token)

## [Adding ImagePullSecrets to a service account](https://github.com/kubernetes/kubernetes/blob/21a14eccf2ee2244d687653cad91b8f99f56a426/docs/user-guide/service-accounts.md#adding-imagepullsecrets-to-a-service-account)

Suppose we have an existing service account named "build-robot" as mentioned above, and we create a new secret manually.

## Service account automation

1. Service Account Admission Controller

It is part of the apiserver. It acts synchronously to modify pods as they are created or updated. When this plugin (Admission Controller) is active (and it is by default on most distributions), then it does the following when a pod is created or modified:


- If the pod does not have a ServiceAccount set, it sets the ServiceAccount to default.
- It ensures that the ServiceAccount referenced by the pod exists, and otherwise rejects it.
- If the pod does not contain any ImagePullSecrets, then ImagePullSecrets of the ServiceAccount are added to the pod.
- It adds a volume to the pod which contains a token for API access.
- It adds a volumeSource to each container of the pod mounted at /var/run/secrets/kubernetes.io/serviceaccount.

2. Token Controller

TokenController runs as part of controller-manager. It acts asynchronously. It:

- observes serviceAccount creation and creates a corresponding Secret to allow API access.
- observes serviceAccount deletion and deletes all corresponding ServiceAccountToken Secrets
- observes secret addition, and ensures the referenced ServiceAccount exists, and adds a token to the secret if needed
- observes secret deletion and removes a reference from the corresponding ServiceAccount if needed

**To create additional API tokens**

A controller loop ensures a secret with an API token exists for each service account. To create additional API tokens for a service account, create a secret of type ServiceAccountToken with an annotation referencing the service account, and the controller will update it with a generated token: (ex: secret.json)

```json
{
    "kind": "Secret",
    "apiVersion": "v1",
    "metadata": {
        "name": "mysecretname",
        "annotations": {
            "kubernetes.io/service-account.name": "myserviceaccount"
        }
    },
    "type": "kubernetes.io/service-account-token"
}
```

```bash
kubectl create -f ./secret.json
kubectl describe secret mysecretname
# To delete/invalidate a service account token
kubectl delete secret mysecretname
```

3. Service Account Controller

Service Account Controller manages ServiceAccount inside namespaces, and ensures a ServiceAccount named "default" exists in every active namespace.
