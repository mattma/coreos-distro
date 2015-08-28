## Generate certs

```bash
cd /path/to/coreos-distro
./setup/utils/certs.sh
```

Retrieve your certs

```bash
cd ./setup/tmp/easy-rsa-master/easyrsa3

# CA_CERT_BASE64: ca.crt
ls -lash /pki/ca.crt

# issued: kube-master.crt, kubecfg.crt, kubelet.crt
ls -lash ./pki/issued

# private: ca.key, kube-master.key, kubecfg.key, kubelet.key
ls -lash ./pki/private
```

### Three files needed on Master node

You will end up with the following files (we will use these variables later on)

- CA_CERT (./setup/tmp/easy-rsa-master/easyrsa3/pki/ca.crt)

put in on node where apiserver runs, in e.g. /srv/kubernetes/ca.crt

- MASTER_CERT

signed by CA_CERT
put in on node where apiserver runs, in e.g. /srv/kubernetes/server.crt

- MASTER_KEY

put in on node where apiserver runs, in e.g. /srv/kubernetes/server.key

- KUBELET_CERT || KUBELET_KEY

optional


**CA_CERT, MASTER_CERT, MASTER_KEY**

Note: The name is vary, here is `kube-master` due to the `Vagrantfile` set the master machine name to `kube-master`.
You need to update the variable inside `./setup/utils/certs.sh` file. The file location is:

```bash
ls -lash ./setup/tmp/easy-rsa-master/easyrsa3/pki/ca.crt
ls -lash ./setup/tmp/easy-rsa-master/easyrsa3/pki/issued/kube-master.crt
ls -lash ./setup/tmp/easy-rsa-master/easyrsa3/pki/private/kube-master.key
```

```bash
mkdir -p ./setup/tmp/kubernetes/
cp ./setup/tmp/easy-rsa-master/easyrsa3/pki/ca.crt ./setup/tmp/kubernetes/ca.crt
cp ./setup/tmp/easy-rsa-master/easyrsa3/pki/issued/kube-master.crt ./setup/tmp/kubernetes/server.crt
cp ./setup/tmp/easy-rsa-master/easyrsa3/pki/private/kube-master.key ./setup/tmp/kubernetes/server.key
```

Then, need to be run on Master node path

```bash
./setup/tmp/kubernetes/ca.crt:/srv/kubernetes/ca.crt
./setup/tmp/kubernetes/server.crt:/srv/kubernetes/server.crt
./setup/tmp/kubernetes/server.key:/srv/kubernetes/server.key
```

## Generate Credentials

The admin user (and any users) need a token (long alphanumeric strings) or a password to identify them.

### Generate a new token

```
TOKEN=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)
```

Your tokens and passwords need to be stored in a file for the apiserver to read.

This guide uses `/var/lib/kube-apiserver/known_tokens.csv`. The format for this file is described in the authentication documentation.

For distributing credentials to clients, the convention in Kubernetes is to put the credentials into a [kubeconfig file](https://github.com/kubernetes/kubernetes/blob/968cbbee5d4964bd916ba379904c469abb53d623/docs/user-guide/kubeconfig-file.md).

### kubeconfig files

In order to easily switch between multiple clusters, a kubeconfig file was defined. This file contains a series of authentication mechanisms and cluster connection information associated with nicknames. It also introduces the concept of a tuple of authentication information (user) and cluster connection information called a context that is also associated with a nickname.

Multiple kubeconfig files are allowed. At runtime they are loaded and merged together along with override options specified from the command line.

#### Master Node

kubeconfig file location, then add certs, keys, and the master IP to the kubeconfig file

```
$HOME/.kube/config
```

Option 1: Firewall-only security

```bash
# If using the firewall-only security option, set the apiserver this way
kubectl config set-cluster $CLUSTER_NAME --server=http://$MASTER_IP --insecure-skip-tls-verify=true
```

[Option 2: Recommended](https://github.com/kubernetes/kubernetes/blob/968cbbee5d4964bd916ba379904c469abb53d623/docs/user-guide/kubeconfig-file.md)

```
CLUSTER_NAME=
CA_CERT=
MASTER_IP=
USER=
CLI_CERT=
CLI_KEY=
TOKEN=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)
CONTEXT_NAME=

# Set the apiserver ip, client certs, and user credentials.
kubectl config set-cluster $CLUSTER_NAME --certificate-authority=$CA_CERT --embed-certs=true --server=https://$MASTER_IP
kubectl config set-credentials $USER --client-certificate=$CLI_CERT --client-key=$CLI_KEY --embed-certs=true --token=$TOKEN

# Set your cluster as the default cluster to use
kubectl config set-context $CONTEXT_NAME --cluster=$CLUSTER_NAME --user=$USER
kubectl config use-context $CONTEXT_NAME
```


### Node


- Config Template

```yaml
apiVersion: v1
kind: Config
users:
- name: kubelet
  user:
    token: ${KUBELET_TOKEN}
clusters:
- name: local
  cluster:
    certificate-authority-data: ${CA_CERT_BASE64_ENCODED}
contexts:
- context:
    cluster: local
    user: kubelet
  name: service-account-context
current-context: service-account-context
```
