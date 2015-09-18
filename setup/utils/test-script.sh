#!/bin/bash

set -e

# http://stackoverflow.com/questions/7069682/how-to-get-arguments-with-flags-in-bash-script

KUBERNETES_VERSION=ENV['KUBERNETES_VERSION'] || 1.0.6
SECURE_BIND_ADDRESS=ENV['SECURE_BIND_ADDRESS'] || 0.0.0.0
SECURE_PORT=ENV['SECURE_PORT'] || 6443

echo ${KUBERNETES_VERSION}
echo ${SECURE_BIND_ADDRESS}
echo ${SECURE_PORT}
