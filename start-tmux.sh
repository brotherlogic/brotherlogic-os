#!/bin/bash

# Ensure the 'prod' session exists
if ! tmux has-session -t brotherlogic-os 2>/dev/null; then
  # Create a new session named 'prod', detached
  cd /workspaces/brotherlogic-os
  tmux new-session -d -s brotherlogic-os
fi
