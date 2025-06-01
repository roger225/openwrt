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

# echo "make dirclean"
make dirclean

# echo "Build tools/compile -j1 V=s ..."
# make tools/compile -j1 V=s

# echo "Build ccache..."
# make tools/ccache/compile || { echo "ccache build failed"; exit 1; }

# # # Clean previous build artifacts
# # echo "Executing: make dirclean..."
# # make dirclean || { echo "make dirclean failed"; exit 1; }
# make tools/ccache/compile -j12
# # Update and install feeds
# make tools/compile -j12

echo "Updating feeds..."
./scripts/feeds update -a || { echo "feeds update failed"; exit 1; }

echo "Installing feeds..."
./scripts/feeds install -a || { echo "feeds install failed"; exit 1; }

# Regenerate configuration
echo "Running make defconfig..."
make defconfig || { echo "make defconfig failed"; exit 1; }

# Download sources and build world
echo "Executing: make -j12 download world..."
make -j12 download world V=s || { echo "Build failed"; exit 1; }

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