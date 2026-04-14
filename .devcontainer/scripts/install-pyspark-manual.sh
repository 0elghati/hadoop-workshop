#!/usr/bin/env bash
# install-pyspark-manual.sh
# Manual fallback installer when rebuilding the container is not possible.

set -euo pipefail

PYSPARK_VERSION="${PYSPARK_VERSION:-3.5.1}"
JAVA_PACKAGE="${JAVA_PACKAGE:-openjdk-11-jdk}"
PROFILE_FILE="${PROFILE_FILE:-${HOME}/.bashrc}"

if ! command -v apt-get >/dev/null 2>&1; then
    echo "ERROR: This script currently supports Debian/Ubuntu images only (apt-get)."
    exit 1
fi

if [ "${EUID}" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo "ERROR: Run as root or install sudo."
        exit 1
    fi
else
    SUDO=""
fi

run_cmd() {
    if [ -n "${SUDO}" ]; then
        ${SUDO} "$@"
    else
        "$@"
    fi
}

append_if_missing() {
    local line="$1"
    touch "${PROFILE_FILE}"
    if ! grep -Fqx "${line}" "${PROFILE_FILE}"; then
        echo "${line}" >> "${PROFILE_FILE}"
    fi
}

echo ""
echo "[1/4] Installing system dependencies..."
run_cmd apt-get update
run_cmd apt-get install -y --no-install-recommends \
    "${JAVA_PACKAGE}" \
    python3 \
    python3-pip \
    python3-venv \
    procps \
    curl

echo "[2/4] Installing PySpark ${PYSPARK_VERSION}..."
run_cmd env PIP_BREAK_SYSTEM_PACKAGES=1 python3 -m pip install --no-cache-dir --upgrade pip
run_cmd env PIP_BREAK_SYSTEM_PACKAGES=1 python3 -m pip install --no-cache-dir "pyspark==${PYSPARK_VERSION}"

echo "[3/4] Writing shell configuration to ${PROFILE_FILE}..."
append_if_missing ""
append_if_missing "# PySpark environment"
append_if_missing "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
append_if_missing "export PYSPARK_PYTHON=/usr/bin/python3"
append_if_missing "export PYSPARK_DRIVER_PYTHON=/usr/bin/python3"
append_if_missing "alias pyspark-version='python3 -c \"import pyspark; print(pyspark.__version__)\"'"

echo "[4/4] Verifying install..."
python3 - <<'PY'
import pyspark
print(f"PySpark version: {pyspark.__version__}")
PY

java -version

echo ""
echo "Done. Load the new environment in your current shell:"
echo "  source ${PROFILE_FILE}"
