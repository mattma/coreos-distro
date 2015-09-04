1. 'service' `kubernetes-ro` has been deprecated?

2. how to connect to https via client certs instead of token?

any request presenting a client certificate signed by one of the authorities in the client-ca-file is authenticated with an identity corresponding to the CommonName of the client certificate. see setup-security-models.md

3.

```yaml
[Unit]
Description=Install Certs/Keys on Master node
Documentation=https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files

[Service]
Type=oneshot
RemainAfterExit=no
ExecStartPre=-/usr/bin/mkdir -p /srv/kubernetes

# can I write a file on host system using systemd?

[Install]
WantedBy=multi-user.target

[X-Fleet]
Global=true
MachineMetadata=role=master
```

4. When machine is in the NotReady status. Reason: `container runtime is down`

Then I checked `kubelet` status

```bash
Sep 04 18:29:11 kube-node-01 kubelet[1494]: I0904 18:29:11.708799    1494 kubelet.go:1735] Skipping pod synchronization, container runtime is not up.
Sep 04 18:29:13 kube-node-01 kubelet[1494]: W0904 18:29:13.632829    1494 container_manager_linux.go:173] [ContainerManager] Failed to ensure state of "/docker-daemon": failed to find pid of Docker container: fork/exec /usr/bin/pidof: cannot allocate memory
Sep 04 18:29:16 kube-node-01 kubelet[1494]: I0904 18:29:16.710039    1494 kubelet.go:1735] Skipping pod synchronization, container runtime is not up.
```

```bash
core@kube-node-01 ~ $ docker ps
Get http:///var/run/docker.sock/v1.19/containers/json: dial unix /var/run/docker.sock: no such file or directory. Are you trying to connect to a TLS-enabled daemon without TLS?
```

How to restart the Docker daemon?
