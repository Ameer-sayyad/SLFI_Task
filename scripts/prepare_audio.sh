#!/usr/bin/env bash
###############################################################################
# prepare_audio.sh - Audio Preprocessing Script
###############################################################################
# This script converts audio files to the format required by MFA:
#   - Mono channel
#   - 16kHz sample rate
#   - PCM 16-bit encoding
#
# Usage: ./scripts/prepare_audio.sh
# Requirements: ffmpeg
###############################################################################

set -euo pipefail

# Configuration
WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAV_DIR="${WORKDIR}/wav"
OUTPUT_DIR="${WORKDIR}/wav_processed"

echo "======================================================================"
echo "  Audio Preprocessing for MFA"
echo "======================================================================"
echo ""

# Check if ffmpeg is available
if ! command -v ffmpeg &> /dev/null; then
    echo "ERROR: ffmpeg not found. Please install ffmpeg first."
    echo "   macOS: brew install ffmpeg"
    echo "   Linux: sudo apt-get install ffmpeg"
    exit 1
fi

echo "ffmpeg found: $(which ffmpeg)"
echo ""

# Check if input directory exists
if [ ! -d "${WAV_DIR}" ]; then
    echo "ERROR: Input directory not found: ${WAV_DIR}"
    exit 1
fi

# Count input files
input_count=$(find "${WAV_DIR}" -name "*.wav" | wc -l | tr -d ' ')
echo "Found ${input_count} WAV files in ${WAV_DIR}"

if [ "${input_count}" -eq 0 ]; then
    echo "ERROR: No WAV files found in ${WAV_DIR}"
    exit 1
fi
echo ""

# Create output directory
mkdir -p "${OUTPUT_DIR}"
echo "Output directory: ${OUTPUT_DIR}"
echo ""

# Process each WAV file
echo "Processing audio files..."
echo "----------------------------------------------------------------------"

processed=0
failed=0

for f in "${WAV_DIR}"/*.wav; do
    [ -e "$f" ] || continue
    
    base=$(basename "$f")
    out="${OUTPUT_DIR}/${base}"
    
    echo "Processing: ${base}"
    
    # Convert to mono, 16kHz, PCM 16-bit
    if ffmpeg -y -i "$f" -ac 1 -ar 16000 -sample_fmt s16 "${out}" -loglevel error 2>&1; then
        echo "  Converted: ${base}"
        ((processed++))
    else
        echo "  Failed: ${base}"
        ((failed++))
    fi
done

echo "----------------------------------------------------------------------"
echo ""
echo "======================================================================"
echo "  Audio Preprocessing Complete"
echo "======================================================================"
echo ""
echo "Summary:"
echo "   Total files: ${input_count}"
echo "   Processed: ${processed}"
echo "   Failed: ${failed}"
echo ""
echo "Processed audio saved to: ${OUTPUT_DIR}"
echo ""
echo "To use processed audio, update WAV_DIR in run_all.sh:"
echo "   WAV_DIR=\"${OUTPUT_DIR}\""
echo ""
