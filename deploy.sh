#!/usr/bin/env bash
# ---- deploy.sh ----
# Runs ON the target server (e.g. the AWS EC2 instance).
# Pulls the requested image from Docker Hub and (re)starts the container
# on port 80.
#
# Usage (on the server):
#   DOCKERHUB_USER=myuser REPO=dev  IMAGE_TAG=latest ./deploy.sh
#   DOCKERHUB_USER=myuser REPO=prod IMAGE_TAG=latest ./deploy.sh
set -euo pipefail

DOCKERHUB_USER="${DOCKERHUB_USER:-yogabharath}"
REPO="${REPO:-dev}"              # "dev" or "prod"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_NAME="devops-build-app"
HOST_PORT="${HOST_PORT:-80}"

IMAGE_NAME="${DOCKERHUB_USER}/devops-build-${REPO}"

echo "==> Pulling ${IMAGE_NAME}:${IMAGE_TAG}"
docker pull "${IMAGE_NAME}:${IMAGE_TAG}"

if [ "$(docker ps -aq -f name="^${CONTAINER_NAME}$")" ]; then
  echo "==> Stopping/removing existing container: ${CONTAINER_NAME}"
  docker rm -f "${CONTAINER_NAME}"
fi

echo "==> Starting ${CONTAINER_NAME} on port ${HOST_PORT}"
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p "${HOST_PORT}:80" \
  "${IMAGE_NAME}:${IMAGE_TAG}"

echo "==> Waiting for container to become healthy..."
sleep 3

if curl -fsS "http://localhost:${HOST_PORT}/" >/dev/null; then
  echo "==> Deployment OK — site responding on port ${HOST_PORT}"
else
  echo "==> WARNING: site did not respond on port ${HOST_PORT}. Check: docker logs ${CONTAINER_NAME}"
  exit 1
fi
