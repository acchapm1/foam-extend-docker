#!/bin/bash

set -e

# Default values
DOCKER_USERNAME="acchapm1"
IMAGE_NAME="foam-extend"
TAG="4.1"
PLATFORM="linux/amd64"
OPTIMIZATION_LEVEL="multi-stage"
PUSH_IMAGE=false
FLATTEN_IMAGE=false
LOAD_IMAGE=true

# Function to display help message
usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -u, --username       Set the Docker Hub username (default: acchapm1)"
  echo "  -i, --image-name     Set the image name (default: foam-extend)"
  echo "  -v, --version        Set the image version (default: 4.1)"
  echo "  -p, --platform       Set the build platform (default: linux/amd64)"
  echo "  -o, --optimization   Set optimization level:"
  echo "                         multi-stage    : Standard multi-stage build (default)"
  echo "                         ultra          : Ultra-optimized build"
  echo "                         flattened      : Multi-stage + post-build flattening"
  echo "                         ultra-flattened: Ultra-optimized + post-build flattening"
  echo "  --push               Push the image to Docker Hub after building"
  echo "  --flatten            Apply post-build flattening optimization"
  echo "  --no-load            Do not load the image locally after build"
  echo "  -h, --help           Display this help message"
  echo ""
  echo "Examples:"
  echo "  $0                                    # Standard multi-stage build"
  echo "  $0 -o ultra                          # Ultra-optimized build"
  echo "  $0 -o flattened                      # Multi-stage + flattening"
  echo "  $0 -o ultra --push                   # Ultra-optimized + push to registry"
  echo "  $0 -u myuser -i myfoam -v latest     # Custom naming"
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
    -o|--optimization)
      OPTIMIZATION_LEVEL="$2"
      shift 2
      ;;
    --push)
      PUSH_IMAGE=true
      shift
      ;;
    --flatten)
      FLATTEN_IMAGE=true
      shift
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

# Set image tags based on optimization level
BASE_TAG="${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
TEMP_TAG="${BASE_TAG}-temp"
FINAL_TAG="${BASE_TAG}"

# Add optimization suffix to tag
case "$OPTIMIZATION_LEVEL" in
  "multi-stage")
    FINAL_TAG="${BASE_TAG}-optimized"
    DOCKERFILE="Dockerfile"
    ;;
  "ultra")
    FINAL_TAG="${BASE_TAG}-ultra"
    DOCKERFILE="Dockerfile.optimized"
    ;;
  "flattened")
    FINAL_TAG="${BASE_TAG}-flattened"
    DOCKERFILE="Dockerfile"
    FLATTEN_IMAGE=true
    ;;
  "ultra-flattened")
    FINAL_TAG="${BASE_TAG}-ultra-flattened"
    DOCKERFILE="Dockerfile.optimized"
    FLATTEN_IMAGE=true
    ;;
  *)
    echo "Invalid optimization level: $OPTIMIZATION_LEVEL"
    echo "Valid options: multi-stage, ultra, flattened, ultra-flattened"
    exit 1
    ;;
esac

echo "=================================================="
echo "Building foam-extend with optimization level: $OPTIMIZATION_LEVEL"
echo "Using Dockerfile: $DOCKERFILE"
echo "Final image tag: $FINAL_TAG"
echo "Platform: $PLATFORM"
echo "Push to registry: $PUSH_IMAGE"
echo "Post-build flattening: $FLATTEN_IMAGE"
echo "Load image locally: $LOAD_IMAGE"
echo "=================================================="

# Build the Docker image
echo "Building Docker image..."
if [ "$FLATTEN_IMAGE" = true ]; then
  # Build to temporary tag first
  docker buildx build \
    --platform "${PLATFORM}" \
    -f "${DOCKERFILE}" \
    -t "${TEMP_TAG}" \
    --load \
    --progress=plain \
    .
  
  echo "Applying post-build flattening optimization..."
  # Create a container from the image
  CONTAINER_ID=$(docker create "${TEMP_TAG}")
  
  # Export and import to remove unused layers
  docker export "${CONTAINER_ID}" | docker import - "${FINAL_TAG}"
  
  # Clean up
  docker rm "${CONTAINER_ID}"
  docker rmi "${TEMP_TAG}"
  
  echo "Flattening complete!"
  # Optionally push if requested
  if [ "$PUSH_IMAGE" = true ]; then
    echo "Pushing flattened image to registry..."
    docker push "${FINAL_TAG}"
  fi
else
  # Direct build
  if [ "$PUSH_IMAGE" = true ]; then
    LOAD_OR_PUSH="--push"
  elif [ "$LOAD_IMAGE" = true ]; then
    LOAD_OR_PUSH="--load"
  else
    LOAD_OR_PUSH=""
  fi

  docker buildx build \
    --platform "${PLATFORM}" \
    -f "${DOCKERFILE}" \
    -t "${FINAL_TAG}" \
    ${LOAD_OR_PUSH} \
    --progress=plain \
    .
fi

# Display image information
echo "=================================================="
echo "Build completed successfully!"
echo "Image: ${FINAL_TAG}"
echo "Size: $(docker images "${FINAL_TAG}" --format "{{.Size}}")"
echo "=================================================="

# Show usage instructions
echo ""
echo "Usage instructions:"
echo "  # Run interactive container:"
echo "  docker run --rm -it ${FINAL_TAG}"
echo ""
echo "  # Test foam-extend functionality:"
echo "  docker run --rm ${FINAL_TAG} icoFoam -help"
echo ""
echo "  # Run tutorial case:"
echo "  docker run --rm ${FINAL_TAG} bash -c \\\n    cp -r \\\$FOAM_TUTORIALS/incompressible/icoFoam/cavity \\\$FOAM_RUN/ && \\\n    cd \\\$FOAM_RUN/cavity && \\\n    blockMesh && \\\n    icoFoam\\\n"
echo ""

# Optional: Show size comparison if multiple images exist
echo "Size comparison (if available):"
docker images "${DOCKER_USERNAME}/${IMAGE_NAME}" --format "table {{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | head -10

echo ""
echo "Build log complete. Image ready for use!" 