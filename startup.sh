#!/bin/bash

# Generate
CONFIG_TOKEN=$(curl --data "" --header "Authorization: Bearer $TOKEN" https://api.github.com/repos/$GITHUB_REPO/actions/runners/registration-token | jq -r '.token')

# Create the runner and configure it
./config.sh --url https://github.com/$GITHUB_REPO --token $CONFIG_TOKEN --unattended --replace

# Run it
./bin/runsvc.sh
