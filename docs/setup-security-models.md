## Generate cert

**Simple version**

```bash
cd /path/to/coreos-distro
./setup/utils/certs.sh
```

Your certs should be inside `./setup/tmp/kubernetes/`

Login your machine `ROLE=master IP=172.17.8.100 vagrant ssh`

```bash
sudo mkdir -p /srv/kubernetes
sudo touch /srv/kubernetes/ca.crt /srv/kubernetes/server.crt /srv/kubernetes/server.key /srv/kubernetes/tokens.csv
```

```bash
cd /srv/kubernetes/
sudo vi /srv/kubernetes/ca.crt
sudo vi /srv/kubernetes/server.crt
sudo vi /srv/kubernetes/server.key

# modify/insert the value: token, username, username
# E.G: ENY0iagPFjyC5fOoQ79flBBGfds3Vyk2,mattma,mattma
sudo vi /srv/kubernetes/tokens.csv
```

**TL;DR**

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

#### Setup Master Node

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

#### Loading and merging rules

The rules for loading and merging the kubeconfig files are straightforward, but there are a lot of them.  The final config is built in this order:
  1.  Get the kubeconfig  from disk.  This is done with the following hierarchy and merge rules:


      If the CommandLineLocation (the value of the `kubeconfig` command line option) is set, use this file only.  No merging.  Only one instance of this flag is allowed.


      Else, if EnvVarLocation (the value of $KUBECONFIG) is available, use it as a list of files that should be merged.
      Merge files together based on the following rules.
      Empty filenames are ignored.  Files with non-deserializable content produced errors.
      The first file to set a particular value or map key wins and the value or map key is never changed.
      This means that the first file to set CurrentContext will have its context preserved.  It also means that if two files specify a "red-user", only values from the first file's red-user are used.  Even non-conflicting entries from the second file's "red-user" are discarded.


      Otherwise, use HomeDirectoryLocation (~/.kube/config) with no merging.
  1.  Determine the context to use based on the first hit in this chain
      1.  command line argument - the value of the `context` command line option
      1.  current-context from the merged kubeconfig file
      1.  Empty is allowed at this stage
  1.  Determine the cluster info and user to use.  At this point, we may or may not have a context.  They are built based on the first hit in this chain.  (run it twice, once for user, once for cluster)
      1.  command line argument - `user` for user name and `cluster` for cluster name
      1.  If context is present, then use the context's value
      1.  Empty is allowed
  1.  Determine the actual cluster info to use.  At this point, we may or may not have a cluster info.  Build each piece of the cluster info based on the chain (first hit wins):
      1.  command line arguments - `server`, `api-version`, `certificate-authority`, and `insecure-skip-tls-verify`
      1.  If cluster info is present and a value for the attribute is present, use it.
      1.  If you don't have a server location, error.
  1.  Determine the actual user info to use. User is built using the same rules as cluster info, EXCEPT that you can only have one authentication technique per user.
      1. Load precedence is 1) command line flag, 2) user fields from kubeconfig
      1. The command line flags are: `client-certificate`, `client-key`, `username`, `password`, and `token`.
      1. If there are two conflicting techniques, fail.
  1.  For any information still missing, use default values and potentially prompt for authentication information

#### [Kubectl config SUBCOMMAND](https://github.com/kubernetes/kubernetes/blob/968cbbee5d4964bd916ba379904c469abb53d623/docs/user-guide/kubectl/kubectl_config.md)

config modifies kubeconfig files.

The loading order follows these rules: 1. If the --kubeconfig flag is set, then only that file is loaded. The flag may only be set once and no merging takes place. 2. If $KUBECONFIG environment variable is set, then it is used a list of paths (normal path delimitting rules for your system). These paths are merged together. When a value is modified, it is modified in the file that defines the stanza. When a value is created, it is created in the first file that exists. If no files in the chain exist, then it creates the last file in the list. 3. Otherwise, ${HOME}/.kube/config is used and no merging takes place.

1. **kubectl config set-cluster**

Sets a cluster entry in kubeconfig

- CLUSTER_NAME

Any name that you want to give to your cluster. Specifying a name that already exists will merge new fields on top of existing values for those fields.

- CA_CERT

value for flag (--certificate-authority), it is `path/to/certficate/authority`. It will embed certificate authority data for the `CLUSTER_NAME` cluster entry. flag (--embed-certs) embed-certs for the cluster entry in kubeconfig.

- MASTER_IP

server for the cluster entry in kubeconfig


2. **kubectl config set-credentials**

Sets a user entry in kubeconfig Specifying a name that already exists will merge new fields on top of existing values.

- USER

username for the user entry in kubeconfig

- CLI_CERT

value for flag (--client-certificate), it is path to client-certificate for the user entry in kubeconfig. flag (--embed-certs) embed client cert/key for the user entry in kubeconfig

- CLI_KEY

value for flag (--client-key), it is path to client-key for the user entry in kubeconfig

- TOKEN

token for the user entry in kubeconfig. It is bearer_token


3. **kubectl config set-context**

Sets a context entry in kubeconfig Specifying a name that already exists will merge new fields on top of existing values for those fields. Flag (--user) user for the context entry in kubeconfig

- CLUSTER_NAME

cluster nickname for the context entry in kubeconfig

- CONTEXT_NAME

The name of the kubeconfig context to use


4. kubectl config use-context

Sets the current-context in a kubeconfig file. `kubectl config use-context CONTEXT_NAME`

```
CLUSTER_NAME=kube-rocks
CA_CERT=/Users/mattma/Documents/repos/github/coreos-distro/setup/tmp/kubernetes/ca.crt
MASTER_IP=172.17.8.100:6443
USER=mattma
CLI_CERT=/Users/mattma/Documents/repos/github/coreos-distro/setup/tmp/kubernetes/server.crt
CLI_KEY=/Users/mattma/Documents/repos/github/coreos-distro/setup/tmp/kubernetes/server.key
TOKEN=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)
CONTEXT_NAME=rocks

# Note: the USER need to be defined on `/srv/kubernetes/tokens.csv`
# When using token authentication from an http client the apiserver expects an Authorization header with a value of Bearer SOMETOKEN.
#  token, user name, user uid
# ENY0iagPFjyC5fOoQ79flBBGfds3Vyk2,mattma,mattma


# Set the apiserver ip, client certs, and user credentials.
kubectl config set-cluster $CLUSTER_NAME --certificate-authority=$CA_CERT --embed-certs=true --server=https://$MASTER_IP

# Embed client certificate data in the `$USER` entry

# OPTION 1
kubectl config set-credentials $USER --token=$TOKEN

# OPTION 2
# any request presenting a client certificate signed by one of the authorities in the client-ca-file is authenticated with an identity corresponding to the CommonName of the client certificate.
kubectl config set-credentials $USER --client-certificate=$CLI_CERT --client-key=$CLI_KEY --embed-certs=true

# Set your cluster as the default cluster to use
kubectl config set-context $CONTEXT_NAME --cluster=$CLUSTER_NAME --user=$USER
kubectl config use-context $CONTEXT_NAME

# To view your current config file
kubectl config view

kubectl get po --v=10
curl -k -v -XGET --key $CLI_KEY https://172.17.8.100:6443/api
```

[Client certificate authentication](https://github.com/kubernetes/kubernetes/blob/968cbbee5d4964bd916ba379904c469abb53d623/docs/admin/authentication.md) is enabled by passing the --client-ca-file=SOMEFILE option to apiserver. The referenced file must contain one or more certificates authorities to use to validate client certificates presented to the apiserver. If a client certificate is presented and verified, the common name of the subject is used as the user name for the request.

### Setup Node

make a kubeconfig file for the kubelets and kube-proxy.  There are a couple of options for how many distinct files to make: 1. Use the same credential as the admin. (simplest).  2. One token and kubeconfig file for all kubelets, one for all kube-proxy, one for admin. (Used on GCE)


- Config Template

Put the kubeconfig(s) on every node. There are kubeconfigs in `/var/lib/kube-proxy/kubeconfig` and `/var/lib/kubelet/kubeconfig`

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
