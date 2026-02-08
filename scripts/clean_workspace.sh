#!/usr/bin/env bash
###############################################################################
# clean_workspace.sh - Cleanup Script
###############################################################################
# This script cleans up generated files and directories
# Usage: ./scripts/clean_workspace.sh
###############################################################################

set -euo pipefail

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "======================================================================"
echo "  Workspace Cleanup"
echo "======================================================================"
echo ""

# Prompt for confirmation
read -p "This will delete generated files and directories. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo "Cleaning up..."

# Remove generated directories
dirs_to_remove=(
    "${WORKDIR}/corpus"
    "${WORKDIR}/aligned_output"
    "${WORKDIR}/logs"
    "${WORKDIR}/wav_processed"
)

for dir in "${dirs_to_remove[@]}"; do
    if [ -d "$dir" ]; then
        echo "  Removing: $dir"
        rm -rf "$dir"
    fi
done

# Remove zip files
if compgen -G "${WORKDIR}/aligned_output_*.zip" > /dev/null; then
    echo "  Removing: aligned_output_*.zip"
    rm -f "${WORKDIR}"/aligned_output_*.zip
fi

echo ""
echo "✓ Cleanup complete"
echo ""
echo "Preserved directories:"
echo "  - wav/"
echo "  - transcripts/"
echo "  - scripts/"
echo "  - python/"
echo ""
