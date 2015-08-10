#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

DOCKER_HUB_USER=${DOCKER_HUB_USER:-kubernetes}

set -x

docker build -t "${DOCKER_HUB_USER}/update-demo:kitten" images/kitten
docker build -t "${DOCKER_HUB_USER}/update-demo:nautilus" images/nautilus

docker push "${DOCKER_HUB_USER}/update-demo"
