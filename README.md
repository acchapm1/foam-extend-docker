# foam-extend-4.1: Docker & Apptainer Containerization for HPC

This repository provides everything needed to build and run a containerized version of `foam-extend-4.1` for both Docker and Apptainer (Singularity) environments, suitable for HPC clusters.

---

## Recent Changes

- **Dockerfiles** now use **Ubuntu 16.04** and **GCC 4.9** (per official release notes).
- **Build scripts** (`build-foamextended.sh`, `build-foamextended-optimized.sh`) now load images locally by default (`--load`), with a `--no-load` option to disable this.
- **Apptainer support**: Added `Singularity.def`, `build-foam-extend-apptainer.sh`, and `run-foam-extend-apptainer.sh` for easy container creation and execution on HPC systems.

---

## Docker Workflow

### Dockerfile

- **Base image**: `ubuntu:16.04`
- **Compiler**: `gcc-4.9` and `g++-4.9`
- **Builds**: `foam-extend-4.1` from source, applies all required patches and environment setup.
- **Entrypoint**: Automatically configures the shell for foam-extend.

### Build Scripts

#### `build-foamextended.sh`

Automates building the Docker image.  
**Now loads the image locally by default** (`--load`).  
Add `--no-load` to skip loading.

**Usage:**
```bash
./build-foamextended.sh [options]
```
**Options:**
- `-u, --username`    Docker Hub username (default: acchapm1)
- `-i, --image-name`  Image name (default: foam-extend)
- `-v, --version`     Image version tag (default: 4.1)
- `-p, --platform`    Target architecture (default: linux/amd64)
- `--no-load`         Do not load the image locally after build
- `-h, --help`        Show help

#### `build-foamextended-optimized.sh`

Supports multiple optimization levels and flattening.  
**Loads image locally by default** unless `--no-load` is specified.  
Use `--push` to push to Docker Hub.

---

## Apptainer (Singularity) Workflow

### Singularity Definition File

- **File**: `Singularity.def`
- **Base**: Ubuntu 16.04, GCC 4.9, all dependencies, builds foam-extend-4.1
- **Environment**: Sets up all necessary variables for foam-extend

### Build the Apptainer Image

Use the provided script:

```bash
./build-foam-extend-apptainer.sh [output_image.sif]
```
(Default output: `foam-extend-4.1.sif`)

Or manually:
```bash
apptainer build foam-extend-4.1.sif Singularity.def
```

### Run the Apptainer Container

Use the provided script:

```bash
./run-foam-extend-apptainer.sh [image.sif] [host_workdir] [extra_args...]
```
- `image.sif` (optional): Apptainer image (default: foam-extend-4.1.sif)
- `host_workdir` (optional): Host directory to mount as `/work` (default: current directory)
- `extra_args...`: Any extra arguments to pass to the container

**Example:**
```bash
./run-foam-extend-apptainer.sh foam-extend-4.1.sif $PWD icoFoam -help
```

Or run interactively:
```bash
apptainer shell foam-extend-4.1.sif
```

---

## Example: Running on HPC with Apptainer

```bash
#!/bin/bash
#SBATCH --job-name=foam_test
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --mem=4G
#SBATCH --time=01:00:00

CASE_DIR="/path/to/your/case"
SIF_FILE="/path/to/foam-extend-4.1.sif"

apptainer exec --bind "${CASE_DIR}:/work" "${SIF_FILE}" icoFoam
```

---

## Summary

- **Docker**: Build and run locally or on any Docker-enabled system.
- **Apptainer**: Build and run on any HPC system with Apptainer/Singularity.
- **Scripts**: Provided for both build and run workflows, with flexible options.

See individual script comments and the `Singularity.def` for further details.