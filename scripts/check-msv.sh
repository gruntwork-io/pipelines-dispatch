#!/usr/bin/env bash

set -euo pipefail

: "${PIPELINES_CLI_VERSION:? "PIPELINES_CLI_VERSION environment variable must be set"}"

MINIMUM_CLI_VERSION="v0.6.1"

MAJOR_VERSION=$(cut -d. -f1<<<"$PIPELINES_CLI_VERSION" | cut -c 2-)
MINOR_VERSION=$(cut -d. -f2<<<"$PIPELINES_CLI_VERSION")
# The way we prerelease is by appending a `-alpha`, etc to the end of the version
PATCH_VERSION=$(cut -d. -f3<<<"$PIPELINES_CLI_VERSION" | cut -d'-' -f1)

MINIMUM_MAJOR_VERSION=$(cut -d. -f1 <<<"$MINIMUM_CLI_VERSION" | cut -c 2-)
MINIMUM_MINOR_VERSION=$(cut -d. -f2 <<<"$MINIMUM_CLI_VERSION")
MINIMUM_PATCH_VERSION=$(cut -d. -f3 <<<"$MINIMUM_CLI_VERSION")

if [[ "$MAJOR_VERSION" -lt "$MINIMUM_MAJOR_VERSION" ]]; then
    echo "pipelines CLI version $PIPELINES_CLI_VERSION is less than the minimum required version $MINIMUM_CLI_VERSION"
    exit 1
fi

if [[ "$MINOR_VERSION" -lt "$MINIMUM_MINOR_VERSION" ]]; then
    echo "pipelines CLI version $PIPELINES_CLI_VERSION is less than the minimum required version $MINIMUM_CLI_VERSION"
    exit 1
fi

if [[ "$PATCH_VERSION" -lt "$MINIMUM_PATCH_VERSION" ]]; then
    echo "pipelines CLI version $PIPELINES_CLI_VERSION is less than the minimum required version $MINIMUM_CLI_VERSION"
    exit 1
fi
