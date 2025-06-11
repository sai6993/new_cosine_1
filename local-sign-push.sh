#!/bin/bash

IMAGE_NAME="n8n-node-app"
LOCAL_TAG="localhost:5000/$IMAGE_NAME:latest"
REMOTE_TAG="saivenkatvaraprasady/$IMAGE_NAME:latest"

echo "Building Docker image..."
docker build -t $LOCAL_TAG .

echo "Starting local Docker registry..."
docker run -d -p 5000:5000 --name local-registry registry:2 2>/dev/null || true

echo "Pushing image to local registry..."
docker push $LOCAL_TAG

echo "Fetching image digest..."
DIGEST=$(docker image inspect $LOCAL_TAG --format='{{index .RepoDigests 0}}' | cut -d "@" -f 2)

if [[ -z "$DIGEST" ]]; then
  echo "Digest not found. Exiting..."
  exit 1
fi
echo "Digest: $DIGEST"

echo "Signing image..."
COSIGN_PASSWORD=your-password-here cosign sign --key cosign.key $LOCAL_TAG@$DIGEST

echo "Retagging for Docker Hub..."
docker tag $LOCAL_TAG $REMOTE_TAG

echo "Logging into DockerHub..."
echo "your-dockerhub-password" | docker login -u your-dockerhub-username --password-stdin

echo "Pushing signed image to DockerHub..."
docker push $REMOTE_TAG

echo "DONE: Built, signed, and pushed!"

