#!/bin/bash

# Remove runner upon receiving an EXIT signal
function remove_runner {
    echo "\nCaught EXIT signal. Removing runner and exiting.\n"
    REMOVE_TOKEN=$(curl --data "" -H "Authorization: Bearer $TOKEN" https://api.github.com/repos/$GITHUB_REPO/actions/runners/remove-token | jq -r '.token')
    ./config.sh remove --token $REMOVE_TOKEN
    exit $?
}

# Watch for EXIT signal to be able to shut down gracefully
trap remove_runner EXIT

# Get latest binary version for Linux x64
BINARY_URL=$(curl \
  --url https://api.github.com/repos/$GITHUB_REPO/actions/runners/downloads \
  --header "authorization: Bearer $TOKEN" | \
  jq -r '.[] | select(.os=="linux") | select(.architecture=="x64") | .download_url')

# Follow any redirects to download and unpack the binary
curl -L $BINARY_URL | tar xz

# Generate 
CONFIG_TOKEN=$(curl --data "" --header "Authorization: Bearer $TOKEN" https://api.github.com/repos/$GITHUB_REPO/actions/runners/registration-token | jq -r '.token')

# Install dependencies
./bin/installdependencies.sh

# Allow runner to run as root
export RUNNER_ALLOW_RUNASROOT=1

# Create the runner and configure it
./config.sh --url https://github.com/$GITHUB_REPO --token $CONFIG_TOKEN --unattended

# Run it
./run.sh