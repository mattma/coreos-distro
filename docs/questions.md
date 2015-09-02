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
