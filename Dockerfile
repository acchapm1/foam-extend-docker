# Use Ubuntu 16.04 as the base image, as mentioned in the release notes
FROM ubuntu:16.04 AS builder

# Set environment variable to allow non-interactive installation of packages
ENV DEBIAN_FRONTEND=noninteractive

#
# === Build Stage: Install Build Dependencies ===
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # Core build tools
    build-essential \
    git \
    gcc-4.9 \
    g++-4.9 \
    # Build dependencies
    bison \
    flex \
    cmake \
    curl \
    rpm \
    zlib1g-dev \
    libncurses5-dev \
    libreadline-dev \
    libxt-dev \
    mercurial \
    graphviz \
    python \
    python-dev \
    python3 \
    python3-dev \
    gnuplot \
    gnuplot-qt \
    gnuplot-data \
    openmpi-bin \
    libopenmpi-dev \
    ca-certificates && \
    # Set gcc and g++ to point to version 4.9
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 100 && \
    # Clean up apt cache immediately
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create build directory with final installation path
WORKDIR /foam

# Clone the source code
RUN git clone --depth=1 http://git.code.sf.net/p/foam-extend/foam-extend-4.1 foam-extend-4.1

# Set working directory
WORKDIR /foam/foam-extend-4.1

# Configure build environment
RUN echo "export WM_THIRD_PARTY_USE_BISON_27=1" >> etc/prefs.sh && \
    echo "export WM_CC='gcc-4.9'" >> etc/prefs.sh && \
    echo "export WM_CXX='g++-4.9'" >> etc/prefs.sh

# Apply required fixes
RUN sed -i -e 's=rpmbuild --define=rpmbuild --define "_build_id_links none" --define=' ThirdParty/tools/makeThirdPartyFunctionsForRPM && \
    sed -i -e 's/gcc/\$(WM_CC)/' wmake/rules/linux64Gcc/c && \
    sed -i -e 's/g++/\$(WM_CXX)/' wmake/rules/linux64Gcc/c++

# Modify bashrc for MPI build
RUN sed -i -e '50s/^/#/' -e '53s/^#//' etc/bashrc

# Compile foam-extend with correct installation path
RUN bash -c "export foamInstall=/foam && source etc/bashrc && ./Allwmake.firstInstall"

# Clean up build artifacts and unnecessary files
RUN find . -name "*.o" -delete && \
    find . -name "*.a" -delete && \
    find . -name "*.so.*" -delete && \
    find . -name "*.dep" -delete && \
    find . -name "Make" -type d -exec rm -rf {} + 2>/dev/null || true && \
    rm -rf ThirdParty/rpmBuild && \
    rm -rf .git && \
    rm -rf doc/Doxygen && \
    find . -name "*.C" -delete && \
    find . -name "*.H" -delete && \
    find . -name "*.cpp" -delete && \
    find . -name "*.hpp" -delete

#
# === Runtime Stage: Minimal Runtime Environment ===
#
FROM ubuntu:16.04 AS runtime

# Set environment variable
ENV DEBIAN_FRONTEND=noninteractive

# Install only runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # Essential runtime libraries
    libstdc++6 \
    libgcc1 \
    libgomp1 \
    # Basic utilities
    bash \
    # Mathematical libraries
    liblapack3 \
    libblas3 \
    # Graphics libraries (if needed for post-processing)
    libgl1-mesa-glx \
    libglu1-mesa \
    libxt6 \
    # Networking
    ca-certificates \
    # MPI runtime
    openmpi-bin \
    # Python runtime (if needed)
    python3-minimal \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# Create foam user (optional, for security)
RUN useradd -m -s /bin/bash foam && \
    mkdir -p /foam && \
    chown foam:foam /foam

# Copy the built foam-extend from builder stage
COPY --from=builder --chown=foam:foam /foam /foam

# Set working directory
WORKDIR /foam

# Create optimized entrypoint script
COPY --chown=foam:foam <<'EOF' /usr/local/bin/docker-entrypoint.sh
#!/bin/bash
# Source the foam-extend environment variables
export foamInstall=/foam
source /foam/foam-extend-4.1/etc/bashrc
# Set up user directories
mkdir -p $FOAM_RUN
# Execute the command passed to 'docker run'
exec "$@"
EOF

# Make the entrypoint script executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch to foam user
USER foam

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Set default command
CMD ["bash"]