#!/usr/bin/env bash
###############################################################################
# validate_corpus.sh - Corpus Validation Helper Script
###############################################################################
# This script validates the corpus before running alignment
# Usage: ./scripts/validate_corpus.sh
###############################################################################

set -euo pipefail

# Configuration
WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORPUS_DIR="${WORKDIR}/corpus"
MFA_DICT="english_us_arpa"

echo "======================================================================"
echo "  MFA Corpus Validation"
echo "======================================================================"
echo ""

# Check if MFA is available
if ! command -v mfa &> /dev/null; then
    echo "ERROR: MFA not found. Please run ./setup_mfa.sh first"
    echo "   Then activate the environment: conda activate mfa"
    exit 1
fi

echo "MFA found: $(mfa version)"
echo ""

# Check if corpus exists
if [ ! -d "${CORPUS_DIR}" ]; then
    echo "ERROR: Corpus directory not found: ${CORPUS_DIR}"
    echo "   Please run ./run_all.sh to prepare the corpus first"
    exit 1
fi

# Count files
wav_count=$(find "${CORPUS_DIR}" -name "*.wav" | wc -l | tr -d ' ')
lab_count=$(find "${CORPUS_DIR}" -name "*.lab" | wc -l | tr -d ' ')

echo "Corpus Summary:"
echo "   WAV files: ${wav_count}"
echo "   LAB files: ${lab_count}"
echo ""

if [ "${wav_count}" -eq 0 ] || [ "${lab_count}" -eq 0 ]; then
    echo "ERROR: Corpus is incomplete (need both WAV and LAB files)"
    exit 1
fi

# Run validation
echo "Running MFA validation..."
echo "----------------------------------------------------------------------"
mfa validate "${CORPUS_DIR}" "${MFA_DICT}"
echo "----------------------------------------------------------------------"
echo ""
echo "Validation complete"
echo ""
