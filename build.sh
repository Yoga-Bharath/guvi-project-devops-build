#!/usr/bin/env bash
# ---- build.sh ----
# Builds the Docker image for the app and tags it based on the current
# git branch: "dev" branch -> *-dev image, "master"/"main" -> *-prod image.
#
# Usage:
#   ./build.sh
#   DOCKERHUB_USER=myuser ./build.sh
#   BRANCH=master IMAGE_TAG=v1 DOCKERHUB_USER=myuser PUSH=true ./build.sh
set -euo pipefail

DOCKERHUB_USER="${DOCKERHUB_USER:-yogabharath}"
BRANCH="${BRANCH:-${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo dev)}}"
BRANCH="${BRANCH##*/}"   # strip "origin/" if Jenkins passes GIT_BRANCH=origin/dev
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)}"
PUSH="${PUSH:-false}"

if [[ "$BRANCH" == "master" || "$BRANCH" == "main" ]]; then
  REPO="prod"
else
  REPO="dev"
fi

IMAGE_NAME="${DOCKERHUB_USER}/devops-build-${REPO}"

echo "==> Branch:      ${BRANCH}"
echo "==> Target repo: ${IMAGE_NAME}"
echo "==> Tag:         ${IMAGE_TAG}"

docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" -t "${IMAGE_NAME}:latest" .

echo "==> Build complete: ${IMAGE_NAME}:${IMAGE_TAG}"

# Persist details for later stages (e.g. Jenkins push/deploy stages)
{
  echo "IMAGE_NAME=${IMAGE_NAME}"
  echo "IMAGE_TAG=${IMAGE_TAG}"
  echo "REPO=${REPO}"
} > .last_build.env

if [[ "$PUSH" == "true" ]]; then
  echo "==> Pushing ${IMAGE_NAME}:${IMAGE_TAG} and :latest to Docker Hub"
  docker push "${IMAGE_NAME}:${IMAGE_TAG}"
  docker push "${IMAGE_NAME}:latest"
fi
