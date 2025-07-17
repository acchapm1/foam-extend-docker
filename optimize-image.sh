#!/bin/bash

# optimize-image.sh - Additional optimization script for foam-extend container
# Run this after building your Docker image

set -e

IMAGE_NAME="${1:-foam-extend:4.1}"
OPTIMIZED_NAME="${2:-foam-extend:4.1-optimized}"

echo "Optimizing Docker image: $IMAGE_NAME"

# Create a container from the image
CONTAINER_ID=$(docker create "$IMAGE_NAME")

# Export and import to remove unused layers
echo "Flattening image layers..."
docker export "$CONTAINER_ID" | docker import - "$OPTIMIZED_NAME"

# Clean up temporary container
docker rm "$CONTAINER_ID"

# Show size comparison
echo "Size comparison:"
echo "Original: $(docker images "$IMAGE_NAME" --format "{{.Size}}")"
echo "Optimized: $(docker images "$OPTIMIZED_NAME" --format "{{.Size}}")"

# Optional: Remove original image
read -p "Remove original image? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker rmi "$IMAGE_NAME"
    echo "Original image removed"
fi

echo "Optimization complete. Use: docker run -it $OPTIMIZED_NAME" 