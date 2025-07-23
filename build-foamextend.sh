#!/bin/bash

set -e

# Default values
DOCKER_USERNAME="acchapm1"
IMAGE_NAME="foam-extend"
TAG="4.1"
PLATFORM="linux/amd64"
LOAD_IMAGE=true

# Function to display help message
usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -u, --username    Set the Docker Hub username (default: acchapm1)"
  echo "  -i, --image-name  Set the image name (default: foam-extend)"
  echo "  -v, --version     Set the image version (default: 4.1)"
  echo "  -p, --platform    Set the build platform (default: linux/amd64)"
  echo "  --no-load         Do not load the image locally after build"
  echo "  -h, --help        Display this help message"
  exit 1
}

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -u|--username)
      DOCKER_USERNAME="$2"
      shift 2
      ;;
    -i|--image-name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    -v|--version)
      TAG="$2"
      shift 2
      ;;
    -p|--platform)
      PLATFORM="$2"
      shift 2
      ;;
    --no-load)
      LOAD_IMAGE=false
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Build the Docker image
if [ "$LOAD_IMAGE" = true ]; then
  docker buildx build \
    --platform "${PLATFORM}" \
    -t "${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}" \
    --load \
    --progress=plain \
    .
else
  docker buildx build \
    --platform "${PLATFORM}" \
    -t "${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}" \
    --progress=plain \
    .
fi

echo "Successfully built ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
