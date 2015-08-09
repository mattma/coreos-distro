## Etcdctl installation and configuration

**[Installation](https://github.com/coreos/etcd/releases)**

```bash
curl -L  https://github.com/coreos/etcd/releases/download/v2.1.1/etcd-v2.1.1-darwin-amd64.zip -o etcd-v2.1.1-darwin-amd64.zip
unzip etcd-v2.1.1-darwin-amd64.zip
cd etcd-v2.1.1-darwin-amd64
mv ./etcd-v2.1.1-darwin-amd64/etcdctl /usr/local/bin/etcdctl
```

**Running `etcdctl` from external host**

```bash
export ETCDCTL_PEERS=http://172.17.8.100:4001
# list all directory in the current Etcd cluster
etcdctl ls /
```

## Fleet installation and configuration

**Running `fleetctl` from external host**

1. [download `fleet` binary](https://github.com/coreos/fleet/releases). make sure you download the version that matches the version of fleet running on the CoreOS cluster.

2. SSH access for a user to at least one host in the cluster

3. ssh-agent running on a user’s machine with the necessary identity

In order to satisfy #2 and #3 above, i added following to `.ssh/config` on the separate machine where I am running `fleetctl`. Vagrant `insecure_private_key` is available in `~/.vagrant.d`, which i have copied to shared directory `/vagrant`.

```bash
# ~/.ssh/config
Host core-01
 User core
 HostName 172.17.8.100
 IdentityFile ~/.vagrant.d/insecure_private_key
```

4. Once the fleetctl binary is installed and communication is established, run following command. required.

```bash
rm -rf ~/.fleetctl/known_hosts
vi ~/.ssh/config  #update the HOST name to match $instance_name_prefix in vagrantfile
rm ~/.vagrant.d/insecure_private_key

vagrant up

# It doesn’t matter which instance you use as the other end of your SSH tunnel,
export FLEETCTL_TUNNEL=172.17.8.100
ssh-add  ~/.vagrant.d/insecure_private_key
fleetctl list-machines
```

**After reload provision or new setup**

```bash
rm -rf ~/.fleetctl/known_hosts
ssh-add  ~/.vagrant.d/insecure_private_key
export FLEETCTL_TUNNEL=172.17.8.100
fleetctl list-machines
```

**Using `fleetctl` to deploy unit-files**

```bash
cd units
# Submit the “kubernetes apiserver” to CoreOS cluster
fleetctl submit kube-apiserver.service

# Start the service
fleetctl start kube-apiserver.service

# Check status
fleetctl list-units

# Read the service file
fleetctl cat kube-apiserver.service

# Check the status/history of the service
fleetctl status kube-apiserver.service

# output the logs
# pass -f flag to streams the output of the service on terminal
fleetctl journal (-f) kube-apiserver.service

# etcdctl setter and getter
etcdctl set first-etcd-key "Hello World"
etcdctl get first-etcd-key   # Hello World

# verify etcd can set a value
etcdctl ls SETTER_NAME
```

- using `systemctl` and `journalctl`

```bash
# To start a new unit, we need to tell systemd to create the symlink and then start the file
systemctl enable /etc/systemd/system/hello.service
systemctl start hello.service

# To verify the unit started, list of containers running with `docker ps` and read the unit's output with `journalctl`
journalctl -f -u hello.service
```

## Kubectl installation and config

#### Installation

```bash
KUBERNETES_VERSION=1.0.2
PLATFORM="darwin"

# wget -q --no-check-certificate -L -O /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/${PLATFORM}/amd64/kubectl"
wget -q --no-check-certificate -L -O /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v1.0.1/bin/darwin/amd64/kubectl"
chmod +x /usr/local/bin/kubectl
```

#### Connect to Kubernetes API Server

Once you've located the kube-apiserver set the KUBERNETES_MASTER environment variable, which configures the `kubectl` client use this API server:

```bash
export KUBERNETES_MASTER="http://172.17.8.100:8080"
```
