#!/bin/bash
set -euo pipefail
set -x

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <TEST_BUILD>" >&2
    exit 1
fi

TEST_BUILD="$1"
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

read -r -d '' container_script <<'BASH' || true
set -euo pipefail
apt-get update
apt-get install -y --no-install-recommends git build-essential
python -m ensurepip --default-pip
pip install poetry==2.5.1
poetry install --without=docs --with=dev
poetry run invoke test
BASH

docker run --rm \
    -e TEST_BUILD="$TEST_BUILD" \
    "${MFR_TEST_IMAGE}" bash -lc "$container_script"
