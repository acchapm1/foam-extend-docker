#!/bin/bash

set -e

IMAGE_NAME="foam-extend-4.1.sif"
WORKDIR=$(pwd)

if [ $# -ge 1 ] && [[ "$1" == *.sif ]]; then
  IMAGE_NAME="$1"
  shift
fi

if [ $# -ge 1 ]; then
  WORKDIR="$1"
  shift
fi

echo "Running Apptainer image: $IMAGE_NAME"
echo "Mounting host directory: $WORKDIR to /work inside the container"
apptainer exec --bind "$WORKDIR":/work -W /work -H "$WORKDIR" -C -e "$IMAGE_NAME" bash --login "$@" 