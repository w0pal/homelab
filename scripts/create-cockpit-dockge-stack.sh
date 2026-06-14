#!/bin/bash
set -e

echo "Creating Dockge stack symlink for Cockpit..."
sudo mkdir -p /home/homeserver/dockge/stacks/cockpit
sudo ln -sf /home/homeserver/homelab/services/cockpit/docker-compose.yml \
  /home/homeserver/dockge/stacks/cockpit/docker-compose.yml

echo "Done! Reload Dockge to see the Cockpit stack."
