#!/bin/bash
set -e

echo "🚀 Kalisi Demo Starting..."

# Check if port 22 is exposed (dev mode detection)
# Simple approach: Check if ENABLE_SSH env var is set or if we can detect port mapping
DEV_MODE=false

# Method 1: Environment variable (most reliable)
if [ "${ENABLE_SSH}" = "true" ]; then
    DEV_MODE=true
    export DEV_MODE=true
    echo "🛠️  Developer mode enabled via ENABLE_SSH - SSH will be available"
# Method 2: Check if port 22 can be bound (means Docker exposed it)
elif nc -z 0.0.0.0 22 2>/dev/null; then
    DEV_MODE=true
    export DEV_MODE=true
    echo "🛠️  Developer mode detected - port 22 is exposed"
else
    echo "📦 Simple mode - Web UI only"
fi

# Start Redis
echo "Starting Redis..."
redis-server --daemonize yes --dir /data/redis --appendonly yes
sleep 2

# Install Neo4j if not present
if ! command -v neo4j >/dev/null 2>&1; then
    echo "Installing Neo4j (first run only, this takes ~1 minute)..."
    apt-get update >/dev/null 2>&1
    DEBIAN_FRONTEND=noninteractive apt-get install -y neo4j >/dev/null 2>&1
    echo "Neo4j installed successfully"
else
    echo "Neo4j already installed, skipping..."
fi

# Configure and start Neo4j
echo "Configuring Neo4j..."
# Update Neo4j configuration
sed -i 's/#server.default_listen_address=localhost/server.default_listen_address=0.0.0.0/' /etc/neo4j/neo4j.conf
sed -i 's/server.directories.data=.*/server.directories.data=\/data\/neo4j\/data/' /etc/neo4j/neo4j.conf
sed -i 's/server.directories.logs=.*/server.directories.logs=\/data\/neo4j\/logs/' /etc/neo4j/neo4j.conf
echo "dbms.security.auth_enabled=false" >> /etc/neo4j/neo4j.conf
mkdir -p /data/neo4j/data /data/neo4j/logs
chown -R neo4j:neo4j /data/neo4j
echo "Starting Neo4j..."
neo4j start
sleep 10

# Start SSH if in dev mode
if [ "$DEV_MODE" = "true" ]; then
    echo "Starting SSH server..."
    /usr/sbin/sshd
    echo "SSH available on port 22 (mapped to 2222)"
fi

# Wait for services
echo "Waiting for services..."
for i in {1..30}; do
    if redis-cli ping >/dev/null 2>&1 && curl -s http://localhost:7474 >/dev/null 2>&1; then
        echo "✅ All services ready!"
        break
    fi
    sleep 1
done

# Start the demo server
echo "Starting Kalisi Demo Server..."
echo "Access at: https://localhost:8443"
if [ "$DEV_MODE" = "true" ]; then
    echo "SSH: ssh -p 2222 devuser@localhost (password: devpass)"
fi

# Run the server in foreground
exec /usr/local/bin/kalisi-demo