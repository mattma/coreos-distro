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
You need to update the variable inside `./setup/utils/certs.sh` file

```bash
ls -lash ./setup/tmp/easy-rsa-master/easyrsa3/pki/ca.crt
ls -lash ./setup/tmp/easy-rsa-master/easyrsa3/pki/issued/kube-master.crt
ls -lash ./setup/tmp/easy-rsa-master/easyrsa3/pki/private/kube-master.key
```
