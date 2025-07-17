# Docker Image Optimization Guide for foam-extend-4.1

This guide explains various optimization strategies to minimize the Docker image size while maintaining functionality.

## Optimization Strategies Implemented

### 1. Multi-Stage Build (60-70% size reduction)
- **Builder stage**: Contains all build tools and dependencies
- **Runtime stage**: Contains only runtime dependencies and compiled binaries
- **Benefit**: Removes ~2GB of build tools from final image

### 2. Selective Dependency Installation
- **Build stage**: Full development packages
- **Runtime stage**: Only essential runtime libraries
- **Removed**: gcc, g++, make, cmake, development headers, documentation

### 3. Aggressive Cleanup
- **Build artifacts**: `*.o`, `*.a`, `*.so.*`, `*.dep` files
- **Source code**: `*.C`, `*.H`, `*.cpp`, `*.hpp` files (after compilation)
- **Documentation**: Doxygen docs, PDFs, man pages
- **Version control**: `.git` directories
- **Temporary files**: Build caches, temporary directories

### 4. Layer Optimization
- **Combined RUN commands**: Reduces layer count
- **Immediate cleanup**: `apt-get clean` in same layer as install
- **Single git clone**: `--depth=1` for shallow clone

### 5. Binary Stripping
- **Strip debug symbols**: Reduces binary size by 20-30%
- **Remove unneeded symbols**: Further size reduction

### 6. Security Enhancements
- **Non-root user**: Runs as `foam` user
- **Minimal attack surface**: Fewer installed packages

## File Structure

```
.
├── Dockerfile                 # Standard multi-stage build
├── Dockerfile.optimized      # Ultra-optimized version
├── .dockerignore             # Excludes unnecessary files
├── optimize-image.sh         # Post-build optimization script
└── OPTIMIZATION.md           # This guide
```

## Usage Options

### Option 1: Standard Multi-Stage Build
```bash
docker build -t foam-extend:4.1 .
```

### Option 2: Ultra-Optimized Build
```bash
docker build -f Dockerfile.optimized -t foam-extend:4.1-ultra .
```

### Option 3: Post-Build Optimization
```bash
docker build -t foam-extend:4.1-temp .
./optimize-image.sh foam-extend:4.1-temp foam-extend:4.1-final
```

## Size Comparison

| Version | Estimated Size | Trade-offs |
|---------|----------------|------------|
| Original | ~4-5 GB | Full development environment |
| Multi-stage | ~1.5-2 GB | No build tools, source code removed |
| Ultra-optimized | ~800MB-1.2GB | Minimal runtime, tutorials preserved |
| Flattened | ~700MB-1GB | Single layer, fastest startup |

## Trade-offs and Considerations

### What You Lose:
- **Source code**: Cannot modify or recompile foam-extend
- **Build tools**: Cannot compile custom solvers in container
- **Documentation**: Reduced documentation (can be accessed externally)
- **Debugging**: Stripped binaries harder to debug

### What You Keep:
- **All executables**: All foam-extend solvers and utilities
- **Tutorial cases**: Working examples and test cases
- **Runtime libraries**: Full foam-extend functionality
- **Environment setup**: Proper foam-extend environment

## Customization Options

### For Development Work:
If you need to compile custom solvers, use the standard Dockerfile or add development packages to the runtime stage:

```dockerfile
# Add to runtime stage
RUN apt-get update && \
    apt-get install -y gcc-5 g++-5 make && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
```

### For Production Use:
Use the ultra-optimized version or add specific runtime dependencies as needed.

### For Specific Use Cases:
- **HPC clusters**: Use multi-stage build with MPI support
- **CI/CD**: Use ultra-optimized for faster pipeline execution
- **Development**: Use standard build with preserved source code

## Performance Impact

- **Build time**: Multi-stage builds take slightly longer
- **Runtime performance**: No impact on foam-extend performance
- **Container startup**: Faster due to smaller image size
- **Network transfer**: Significantly faster push/pull operations

## Maintenance

- **Regular updates**: Rebuild when base image updates
- **Security scanning**: Smaller surface area, fewer vulnerabilities
- **Version control**: Tag images with foam-extend version

## Advanced Optimization Techniques

### 1. Distroless Base Images
For maximum security and minimal size:
```dockerfile
FROM gcr.io/distroless/cc-debian11
```

### 2. Alpine Linux
Smaller base image (~5MB vs ~64MB):
```dockerfile
FROM alpine:3.18
```

### 3. Custom Base Image
Create a minimal Ubuntu image with only required packages.

### 4. Multi-Architecture Builds
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t foam-extend:4.1 .
```

## Verification

After optimization, verify functionality:
```bash
# Test basic functionality
docker run --rm foam-extend:4.1 icoFoam -help

# Test tutorial case
docker run --rm foam-extend:4.1 bash -c "
  cp -r \$FOAM_TUTORIALS/incompressible/icoFoam/cavity \$FOAM_RUN/
  cd \$FOAM_RUN/cavity
  blockMesh
  icoFoam
"
```

## Troubleshooting

### Common Issues:
1. **Missing libraries**: Add to runtime stage
2. **Permission errors**: Check user permissions
3. **Environment variables**: Verify foam-extend environment setup
4. **Path issues**: Ensure correct PATH in entrypoint

### Debug Commands:
```bash
# Check image size
docker images foam-extend:4.1

# Inspect layers
docker history foam-extend:4.1

# Debug runtime environment
docker run --rm -it foam-extend:4.1 env | grep FOAM
```

## Conclusion

The multi-stage build approach provides the best balance of size reduction and functionality. The ultra-optimized version achieves maximum size reduction but with some trade-offs in flexibility. Choose the approach that best fits your use case. 