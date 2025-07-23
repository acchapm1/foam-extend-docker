#!/bin/bash

set -e

IMAGE_NAME="foam-extend-4.1.sif"
DEF_FILE="Singularity.def"

if [ $# -ge 1 ]; then
  IMAGE_NAME="$1"
fi

echo "Building Apptainer image: $IMAGE_NAME from $DEF_FILE"
apptainer build --fakeroot "$IMAGE_NAME" "$DEF_FILE"
echo "Build complete: $IMAGE_NAME" 