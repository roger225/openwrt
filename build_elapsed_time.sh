#!/bin/bash

# Generate log filename with timestamp
timestamp=$(date +%Y%m%d_%H%M)
logfile="build_${timestamp}.build.log"

# Record start time
start_time=$(date +%s)

# Redirect stdout and stderr to both screen and log file
exec > >(tee -i "$logfile") 2>&1

echo "==================================="
echo "Starting OpenWrt build process..."
echo "Log file: $logfile"
echo "==================================="

# Set your CPU core count for parallel builds
NUM_CORES=$(nproc)

# echo "Cleaning previous build directories..."
# rm -rf build_dir staging_dir tmp

# # Clean previous build artifacts (optional)
# echo "Running: make dirclean..."
# make dirclean || { echo "make dirclean failed"; exit 1; }

# # Skip ccache build if already present
# if [ -x "staging_dir/host/bin/ccache" ]; then
#   echo "ccache already built. Skipping build."
# else
#   echo "Building ccache..."
#   make tools/ccache/compile V=s || { echo "ccache build failed"; exit 1; }
# fi

if [ ! -x "staging_dir/host/bin/ccache" ]; then
  echo "Error: ccache binary still missing after build!"
  exit 1
fi

# Show ccache version
echo "Show ccache version..."
staging_dir/host/bin/ccache --version

# Update and install feeds
echo "Updating feeds..."
cp .config .config.backup
./scripts/feeds update -a || { echo "feeds update failed"; exit 1; }

echo "Installing feeds..."
./scripts/feeds install -a || { echo "feeds install failed"; exit 1; }

# Load default configuration (if needed, after copying new .config)
echo "Running make defconfig..."
cp .config.backup .config
make defconfig || { echo "make defconfig failed"; exit 1; }

# # Build the rest of tools in parallel
# echo "Building all tools..."
# make -j"$NUM_CORES" tools/install V=s || { echo "tools build failed"; exit 1; }

# # Build the toolchain in parallel
# echo "Building toolchain..."
# make -j"$NUM_CORES" toolchain/install V=s || { echo "toolchain build failed"; exit 1; }

# echo "Checking tools and toolchain stamps..."
# find staging_dir/host/stamp/ -name '*.installed' -exec ls -lh {} +
# find staging_dir/toolchain-*/stamp/ -name '*.installed' -exec ls -lh {} +

# Download sources and build everything (main build)
echo "Executing: make -j$NUM_CORES download world..."
make -j"$NUM_CORES" download world V=s || { echo "Build failed"; exit 1; }

rm .config.backup
# Record end time
end_time=$(date +%s)

# Calculate elapsed time
elapsed=$((end_time - start_time))
minutes=$((elapsed / 60))
seconds=$((elapsed % 60))

echo "==================================="
echo "Build completed successfully."
echo "Total time spent: ${minutes} min ${seconds} sec"
echo "==================================="