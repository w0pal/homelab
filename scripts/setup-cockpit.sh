#!/bin/bash
set -e

echo "=== Step 1: Fix SSH password auth for localhost (required by Cockpit) ==="
sudo rm -f /etc/ssh/ssh_config.d/02-enable-passwords.conf
sudo mkdir -p /etc/ssh/sshd_config.d
sudo tee /etc/ssh/sshd_config.d/02-enable-passwords.conf << 'EOF'
Match Address 127.0.0.1,::1
    PasswordAuthentication yes
EOF

echo "=== Step 2: Restart SSH ==="
sudo systemctl try-restart sshd

echo "=== Step 3: Stop and remove system Cockpit ==="
sudo systemctl disable --now cockpit cockpit.socket
sudo apt purge -y cockpit-ws

echo "=== Step 4: Create Dockge stack symlink ==="
STACK_DIR="/home/homeserver/dockge/stacks/cockpit"
COMPOSE_SRC="/home/homeserver/homelab/services/cockpit/docker-compose.yml"
if [ -L "$STACK_DIR/docker-compose.yml" ] || [ -f "$STACK_DIR/docker-compose.yml" ]; then
    echo "Dockge stack already exists at $STACK_DIR"
else
    sudo mkdir -p "$STACK_DIR"
    sudo ln -sf "$COMPOSE_SRC" "$STACK_DIR/docker-compose.yml"
    echo "Created Dockge stack symlink"
fi

echo ""
echo "Done! Port 9090 is now free for the Cockpit container."
echo "Now run:"
echo "  docker compose -f $COMPOSE_SRC up -d"
