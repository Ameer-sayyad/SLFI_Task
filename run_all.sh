#!/usr/bin/env bash
###############################################################################
# run_all.sh - Main Pipeline Script for MFA Forced Alignment
# Usage: ./run_all.sh
# Prerequisites: Run ./setup_mfa.sh first and activate the conda environment
# path to scripts : /home/chiranjeevi-yarra/miniconda3/envs/mfa/lib/python3.10/site-packages/montreal_forced_aligner
###############################################################################

set -euo pipefail

# =============================================================================
# Configuration Variables (UPDATED FOR YOUR PATH STRUCTURE)
# =============================================================================
WORKDIR="$(pwd)"
WAV_DIR="/home/chiranjeevi-yarra/Downloads/data/ameer/inter_task/wav"
TRANS_DIR="/home/chiranjeevi-yarra/Downloads/data/ameer/inter_task/transcripts"
#WAV_DIR="/home/chiranjeevi-yarra/Downloads/data/ameer/Test6/number_audio_chunks_files"
#TRANS_DIR="/home/chiranjeevi-yarra/Downloads/data/ameer/Test6/number_sent_files"
# WAV_DIR="/home/chiranjeevi-yarra/Downloads/data/HimanGY/pradeep/ssmt_main/Audios/Eng_yt_audios"
# TRANS_DIR="/home/chiranjeevi-yarra/Downloads/data/ameer/Test6/STAGE2(2)_para_to_norm_para"
CORPUS_DIR="${WORKDIR}/my_corpus_task1"
OUTPUT_DIR="${WORKDIR}/aligned_"
# CORPUS_DIR="${WORKDIR}/corpus_sample_test6_3"
# OUTPUT_DIR="${WORKDIR}/aligned_output_sample_test6_3"
MFA_DICT="/home/chiranjeevi-yarra/Downloads/data/mfa-aligner/new_main_dict1.cleaned.txt"
MFA_ACOUSTIC="english_us_arpa"

# =============================================================================
# Logging setup
# =============================================================================
LOG_DIR="${WORKDIR}/logs"
mkdir -p "${LOG_DIR}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/pipeline_${TIMESTAMP}.log"

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

log "======================================================================"
log "  MFA Forced Alignment Pipeline - START"
log "======================================================================"
log ""
log "Audio Directory: ${WAV_DIR}"
log "Text Directory: ${TRANS_DIR}"
log "Corpus Directory: ${CORPUS_DIR}"
log "Output Directory: ${OUTPUT_DIR}"
log ""

# =============================================================================
# Check if MFA is available
# =============================================================================
if ! command -v mfa &> /dev/null; then
    log "ERROR: MFA not found. Please run ./setup_mfa.sh first"
    log "   Then activate the environment: conda activate mfa"
    exit 1
fi

log "MFA found: $(mfa version)"
log ""

# =============================================================================
# Create necessary directories
# =============================================================================
log "Creating directories..."
mkdir -p "${CORPUS_DIR}" "${OUTPUT_DIR}"

log "Cleaning up old MFA cache..."
rm -rf "${CORPUS_DIR}/.mfa" "${CORPUS_DIR}/.backup" "${CORPUS_DIR}/.textgrids"

# ❗ Do NOT delete global MFA models (keeps your modified dictionary safe)
# rm -rf ~/.local/share/Montreal-Forced-Aligner/*   # ← removed intentionally

# Only delete temporary MFA files
rm -rf /tmp/mfa_* 2>/dev/null || true

log "Cleanup complete."
log ""



# =============================================================================
# STEP 1: Collect matching audio-transcript pairs (speaker-wise, number-based)
# =============================================================================
log "======================================================================"
log "STEP 1: Collecting matching audio-transcript pairs (speaker-wise, number-based)"
log "======================================================================"

# Temporarily disable 'exit on error' for this loop
set +e

rm -rf "${CORPUS_DIR:?}/"*
mkdir -p "${CORPUS_DIR}" "${CORPUS_DIR}/skipped"

count=0
skipped_count=0
MATCHED_LIST=()
SKIPPED_LIST=()

# ✅ Write all .wav file paths into a temp file to avoid broken pipes
TMP_WAV_LIST=$(mktemp)
find "${WAV_DIR}" -type f -iname "*.wav" | sort > "${TMP_WAV_LIST}"

# ✅ Now iterate over that list (no pipes = no subshell)
while IFS= read -r wav; do
    [ -z "$wav" ] && continue
    fname=$(basename "${wav}" .wav)
    speaker_dir=$(basename "$(dirname "${wav}")")
    number=$(echo "${fname}" | grep -oE '[0-9]+$')

    log "Checking WAV: ${fname} | speaker='${speaker_dir}' | number='${number}'"

    if [ -z "${number}" ]; then
        log "  ❌ Skipping: No trailing number found."
        cp -v "${wav}" "${CORPUS_DIR}/skipped/" | tee -a "${LOG_FILE}" || true
        SKIPPED_LIST+=("${speaker_dir}/${fname}.wav")
        ((skipped_count++))
        continue
    fi

    txt_match=$(find "${TRANS_DIR}/${speaker_dir}" -type f -iname "*${number}*.txt" 2>/dev/null | head -n 1)

    if [ -n "${txt_match}" ]; then
        mkdir -p "${CORPUS_DIR}/${speaker_dir}"
        cp -v "${wav}" "${CORPUS_DIR}/${speaker_dir}/" | tee -a "${LOG_FILE}"
        cp -v "${txt_match}" "${CORPUS_DIR}/${speaker_dir}/${fname}.lab" | tee -a "${LOG_FILE}"
        log "  ✅ Matched: $(basename "${txt_match}")"
        MATCHED_LIST+=("${speaker_dir}/${fname}.wav ↔ $(basename "${txt_match}")")
        ((count++))
    else
        log "  ❌ No transcript found for: ${fname}"
        cp -v "${wav}" "${CORPUS_DIR}/skipped/" | tee -a "${LOG_FILE}" || true
        SKIPPED_LIST+=("${speaker_dir}/${fname}.wav")
        ((skipped_count++))
    fi
done < "${TMP_WAV_LIST}"

# ✅ Clean up
rm -f "${TMP_WAV_LIST}"

# ✅ Re-enable 'exit on error' after loop
set -e

log "------------------------------------------------------------------"
log "Matched ${count} valid audio-transcript pairs ✅"
log "Skipped ${skipped_count} unmatched audio files ❌"
log "------------------------------------------------------------------"
if (( count > 0 )); then
    log "Matched files (${count}):"
    for m in "${MATCHED_LIST[@]}"; do
        log "  ✅ ${m}"
    done
fi
if (( skipped_count > 0 )); then
    log "Skipped files (${skipped_count}):"
    for s in "${SKIPPED_LIST[@]}"; do
        log "  ❌ ${s}"
    done
fi
log "------------------------------------------------------------------"
log ""

log "Matched ${count} valid audio-transcript pairs ✅"
log "Skipped ${skipped_count} unmatched audio files ❌"
log "------------------------------------------------------------------"

if (( count > 0 )); then
    log "Matched files (${count}):"
    for m in "${MATCHED_LIST[@]}"; do
        log "  ✅ ${m}"
    done
fi
if (( skipped_count > 0 )); then
    log "Skipped files (${skipped_count}):"
    for s in "${SKIPPED_LIST[@]}"; do
        log "  ❌ ${s}"
    done
fi
log "------------------------------------------------------------------"
log ""













# =============================================================================
# STEP 2: Verify Corpus
# =============================================================================
log "======================================================================"
log "STEP 2: Corpus Summary"
log "======================================================================"
wav_count=$(find "${CORPUS_DIR}" -name "*.wav" | wc -l | tr -d ' ')
lab_count=$(find "${CORPUS_DIR}" -name "*.lab" | wc -l | tr -d ' ')
log "WAV files: ${wav_count}"
log "LAB files: ${lab_count}"

if [ "${wav_count}" -eq 0 ] || [ "${lab_count}" -eq 0 ]; then
    log "ERROR: Corpus is incomplete (need matching WAV and LAB files)"
    exit 1
fi
log ""

# =============================================================================
# STEP 3: Check/Download MFA models
# =============================================================================
log "======================================================================"
log "STEP 3: Checking/Downloading MFA models"
log "======================================================================"
log "Dictionary: ${MFA_DICT}"
log "Acoustic Model: ${MFA_ACOUSTIC}"

# log "Downloading dictionary..."
# mfa model download dictionary ${MFA_DICT} 2>&1 | tee -a "${LOG_FILE}" || true

log "Downloading acoustic model..."
mfa model download acoustic ${MFA_ACOUSTIC} 2>&1 | tee -a "${LOG_FILE}" || true
log "Models ready"
log ""

# # =============================================================================
# # STEP 4: Validate corpus
# # =============================================================================
# log "======================================================================"
# log "STEP 4: Validating corpus"
# log "======================================================================"
# VALIDATE_LOG="${LOG_DIR}/validate_${TIMESTAMP}.txt"
# log "Running MFA validation..."
# mfa validate "${CORPUS_DIR}" "${MFA_DICT}" 2>&1 | tee "${VALIDATE_LOG}" | tee -a "${LOG_FILE}" || {
#     log "Validation completed with warnings (this is normal)"
# }
# log "Validation complete (see ${VALIDATE_LOG})"
# log ""


# =============================================================================
# STEP 5: Run forced alignment (Optimized for 8GB RAM systems)
# =============================================================================
log "======================================================================"
log "STEP 5: Running forced alignment"
log "======================================================================"
ALIGN_LOG="${LOG_DIR}/align_${TIMESTAMP}.txt"
log "This may take several minutes depending on corpus size..."
log "Using 2 parallel jobs and limited thread usage for stability."

# ✅ Prevent each job from overusing threads (reduces memory per process)
export OMP_NUM_THREADS=1

# ✅ Run MFA alignment with safe parallelism and all logs captured
mfa align "${CORPUS_DIR}" "${MFA_DICT}" "${MFA_ACOUSTIC}" "${OUTPUT_DIR}" --disable_g2p \
    -j 1 --clean --beam 60 --retry_beam 240 2>&1 | tee "${ALIGN_LOG}" | tee -a "${LOG_FILE}"

# ✅ Post-run result check
if [ $? -eq 0 ]; then
    log "✅ Alignment complete successfully!"
else
    log "❌ ERROR: Alignment failed. Check ${ALIGN_LOG} for detailed output."
    exit 1
fi

log ""


# =============================================================================
# STEP 6: Generate metrics
# # =============================================================================
# log "======================================================================"
# log "STEP 6: Generating metrics"
# log "======================================================================"
# python3 tools/metrics.py "${CORPUS_DIR}" "${OUTPUT_DIR}" "${VALIDATE_LOG}" 2>&1 | tee -a "${LOG_FILE}"
# log ""

# =============================================================================
# STEP 7: Package outputs
# =============================================================================
log "======================================================================"
log "STEP 7: Packaging outputs"
log "======================================================================"
OUTPUT_ZIP="${WORKDIR}/aligned_output_${TIMESTAMP}.zip"
if command -v zip &> /dev/null; then
    log "Creating ZIP archive..."
    zip -r "${OUTPUT_ZIP}" "${OUTPUT_DIR}" "${LOG_DIR}" 2>&1 | tee -a "${LOG_FILE}" || true
    log "Archive created: ${OUTPUT_ZIP}"
else
    log "zip command not found, skipping archive creation"
fi
log ""

# =============================================================================
# Final summary
# =============================================================================
log "======================================================================"
log "  MFA Forced Alignment Pipeline - COMPLETE"
log "======================================================================"
log ""
log "Results:"
log "   - TextGrids: ${OUTPUT_DIR}/"
log "   - Logs: ${LOG_DIR}/"
log "   - Archive: ${OUTPUT_ZIP}"
log ""
log "Next steps:"
log "   1. Review metrics output above"
log "   2. Open TextGrid files in Praat to inspect alignments"
log "   3. Check logs if any issues occurred"
log ""
log "Pipeline log saved to: ${LOG_FILE}"
log ""
