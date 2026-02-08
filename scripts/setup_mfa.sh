#!/usr/bin/env bash
###############################################################################
# setup_mfa.sh - Environment Setup Script for Montreal Forced Aligner
###############################################################################
# This script creates a conda environment and installs MFA
# Usage: ./setup_mfa.sh
###############################################################################

set -euo pipefail

# Configuration
ENV_NAME="mfa"
PYTHON_VERSION="3.10"

echo "======================================================================"
echo "  MFA Environment Setup"
echo "======================================================================"
echo ""

# Check if conda is available
if ! command -v conda &> /dev/null; then
    echo "ERROR: conda not found. Please install Anaconda or Miniconda first."
    echo "   Download from: https://docs.conda.io/en/latest/miniconda.html"
    exit 1
fi

echo "conda found: $(which conda)"
echo ""

# Check if environment already exists
if conda env list | grep -q "^${ENV_NAME} "; then
    echo "Environment '${ENV_NAME}' already exists."
    read -p "   Do you want to remove and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "   Removing existing environment..."
        conda env remove -n ${ENV_NAME} -y
    else
        echo "   Keeping existing environment. Activating it..."
        eval "$(conda shell.bash hook)"
        conda activate ${ENV_NAME}
        echo "Environment '${ENV_NAME}' activated"
        exit 0
    fi
fi

# Create new conda environment
echo "Creating conda environment: ${ENV_NAME} (Python ${PYTHON_VERSION})"
conda create -n ${ENV_NAME} python=${PYTHON_VERSION} -y

# Activate the environment
echo ""
echo "Activating environment..."
eval "$(conda shell.bash hook)"
conda activate ${ENV_NAME}

# Upgrade pip
echo ""
echo "Upgrading pip..."
pip install --upgrade pip

# Install Montreal Forced Aligner and dependencies
echo ""
echo "Installing Montreal Forced Aligner..."

# Install MFA from conda-forge (more reliable than pip)
echo "Installing from conda-forge channel..."
conda install -c conda-forge montreal-forced-aligner -y

# If conda install fails, try pip as fallback
if [ $? -ne 0 ]; then
    echo "Conda install failed, trying pip..."
    pip install montreal-forced-aligner
    
    # Install kalpy separately (common missing dependency)
    echo "Installing kalpy..."
    pip install kalpy
fi

# Verify installation
echo ""
echo "Verifying MFA installation..."
if mfa version 2>&1 | grep -q "montreal-forced-aligner"; then
    echo ""
    echo "======================================================================"
    echo "  SUCCESS! MFA installed successfully"
    echo "======================================================================"
    echo ""
    mfa version
    echo ""
    echo "To use MFA, activate the environment:"
    echo "  conda activate ${ENV_NAME}"
    echo ""
    echo "Then run the main pipeline:"
    echo "  ./run_all.sh"
    echo ""
else
    echo ""
    echo "WARNING: MFA installation may have issues"
    echo "   Try running: conda activate ${ENV_NAME} && mfa version"
    echo "   If you see 'No module named _kalpy' error, run:"
    echo "     conda install -c conda-forge kalpy -y"
    echo ""
fi
