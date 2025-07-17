#!/bin/bash

# test-foamextended.sh - Test script for foam-extend Docker containers

set -e

# Default values
IMAGE_NAME="acchapm1/foam-extend:4.1-optimized"
RUN_TUTORIAL=false
VERBOSE=false

# Function to display help message
usage() {
  echo "Usage: $0 [options] [image_name]"
  echo "Options:"
  echo "  -t, --tutorial       Run a complete tutorial test (cavity case)"
  echo "  -v, --verbose        Enable verbose output"
  echo "  -h, --help           Display this help message"
  echo ""
  echo "Examples:"
  echo "  $0                                           # Basic test with default image"
  echo "  $0 acchapm1/foam-extend:4.1-ultra          # Test specific image"
  echo "  $0 -t acchapm1/foam-extend:4.1-ultra       # Run full tutorial test"
  echo "  $0 -v -t                                    # Verbose tutorial test"
  exit 1
}

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -t|--tutorial)
      RUN_TUTORIAL=true
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    -*)
      echo "Unknown option: $1"
      usage
      ;;
    *)
      IMAGE_NAME="$1"
      shift
      ;;
  esac
done

# Function to run command with optional verbose output
run_test() {
  local test_name="$1"
  local command="$2"
  
  echo "Testing: $test_name"
  
  if [ "$VERBOSE" = true ]; then
    echo "Running: $command"
    if eval "$command"; then
      echo "✓ PASS: $test_name"
    else
      echo "✗ FAIL: $test_name"
      exit 1
    fi
  else
    if eval "$command >/dev/null 2>&1"; then
      echo "✓ PASS: $test_name"
    else
      echo "✗ FAIL: $test_name"
      echo "  Run with -v for verbose output"
      exit 1
    fi
  fi
  echo
}

echo "========================================"
echo "Testing foam-extend container: $IMAGE_NAME"
echo "========================================"

# Test 1: Check if image exists
echo "Checking if image exists..."
if docker images "$IMAGE_NAME" --format "{{.Repository}}:{{.Tag}}" | grep -q "$(echo "$IMAGE_NAME" | cut -d':' -f1)"; then
  echo "✓ Image found: $IMAGE_NAME"
  echo "  Size: $(docker images "$IMAGE_NAME" --format "{{.Size}}")"
else
  echo "✗ Image not found: $IMAGE_NAME"
  echo "  Available images:"
  docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
  exit 1
fi
echo

# Test 2: Basic container startup
run_test "Container startup" "docker run --rm '$IMAGE_NAME' echo 'Container started successfully'"

# Test 3: Environment variables
run_test "Environment variables" "docker run --rm '$IMAGE_NAME' bash -c 'echo \$FOAM_INSTALL_PATH && echo \$FOAM_APP'"

# Test 4: foam-extend help
run_test "icoFoam help" "docker run --rm '$IMAGE_NAME' icoFoam -help"

# Test 5: Other essential utilities
run_test "blockMesh help" "docker run --rm '$IMAGE_NAME' blockMesh -help"
run_test "paraFoam help" "docker run --rm '$IMAGE_NAME' paraFoam -help"

# Test 6: Check important directories
run_test "FOAM_RUN directory" "docker run --rm '$IMAGE_NAME' bash -c 'echo \$FOAM_RUN && ls -la \$FOAM_RUN'"
run_test "FOAM_TUTORIALS directory" "docker run --rm '$IMAGE_NAME' bash -c 'echo \$FOAM_TUTORIALS && ls \$FOAM_TUTORIALS | head -5'"

# Test 7: Full tutorial test (optional)
if [ "$RUN_TUTORIAL" = true ]; then
  echo "Running full tutorial test..."
  echo "This will take a few minutes..."
  
  run_test "Tutorial: Copy cavity case" "docker run --rm '$IMAGE_NAME' bash -c 'cp -r \$FOAM_TUTORIALS/incompressible/icoFoam/cavity \$FOAM_RUN/ && ls \$FOAM_RUN/cavity'"
  
  run_test "Tutorial: Run blockMesh" "docker run --rm '$IMAGE_NAME' bash -c 'cd \$FOAM_RUN/cavity && blockMesh'"
  
  run_test "Tutorial: Run icoFoam (1 iteration)" "docker run --rm '$IMAGE_NAME' bash -c 'cd \$FOAM_RUN/cavity && sed -i \"s/endTime.*/endTime 0.01;/\" system/controlDict && icoFoam'"
  
  echo "✓ Full tutorial test completed successfully!"
fi

echo "========================================"
echo "All tests completed successfully!"
echo "Image: $IMAGE_NAME"
echo "Status: Ready for use"
echo "========================================"

# Show usage examples
echo ""
echo "Usage examples:"
echo "  # Interactive session:"
echo "  docker run --rm -it $IMAGE_NAME"
echo ""
echo "  # Run a case (mount local directory):"
echo "  docker run --rm -v \$(pwd):/workspace -w /workspace $IMAGE_NAME icoFoam"
echo ""
echo "  # Run tutorial case:"
echo "  docker run --rm $IMAGE_NAME bash -c \\"
echo "    cp -r \\\$FOAM_TUTORIALS/incompressible/icoFoam/cavity \\\$FOAM_RUN/ && \\"
echo "    cd \\\$FOAM_RUN/cavity && \\"
echo "    blockMesh && \\"
echo "    icoFoam\\" 