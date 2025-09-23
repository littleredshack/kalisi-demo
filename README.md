# Kalisi Demo

A lightweight demonstration of the Kalisi platform in a single Docker container, featuring Redis, Neo4j, and a Rust-based web API.

## Prerequisites

### Install Docker First!

Before you can use Kalisi Demo, you need Docker installed on your system.

#### macOS
1. Download Docker Desktop from https://www.docker.com/products/docker-desktop/
2. Open the downloaded `.dmg` file
3. Drag Docker to your Applications folder
4. Launch Docker from Applications
5. Wait for the whale icon to appear in your menu bar
6. Test it works: Open Terminal and type `docker --version`

#### Windows
1. Download Docker Desktop from https://www.docker.com/products/docker-desktop/
2. Run the installer
3. Follow the installation wizard
4. Start Docker Desktop
5. Test it works: Open PowerShell and type `docker --version`

#### Linux
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (logout/login after)
sudo usermod -aG docker $USER
```

## Quick Start

### Pull and Run (Simple Mode)

```bash
# Pull the image from GitHub Container Registry
docker pull ghcr.io/littleredshack/kalisi-demo:latest

# Run in simple mode (web UI only)
docker run -d --name kalisi-demo \
  -p 8443:8443 \
  -v kalisi-demo-data:/data \
  ghcr.io/littleredshack/kalisi-demo:latest

# Access the web UI
# Open https://localhost:8443 in your browser
```

### Pull and Run (Developer Mode)

```bash
# Run with SSH access enabled
docker run -d --name kalisi-demo \
  -p 8443:8443 \
  -p 2222:22 \
  -e ENABLE_SSH=true \
  -v kalisi-demo-data:/data \
  ghcr.io/littleredshack/kalisi-demo:latest

# Access via web
# https://localhost:8443

# Access via SSH
ssh -p 2222 devuser@localhost
# Password: devpass
```

## Using the Install Script

For an easier setup, use the provided install script:

```bash
# Download the install script
curl -O https://raw.githubusercontent.com/glensimister/kalisi-demo/main/install.sh
chmod +x install.sh

# Run it
./install.sh

# Choose:
# 1) Simple mode (web only)
# 2) Developer mode (web + SSH)
```

## What's Included

- **Redis** - In-memory data store (port 6379 internally)
- **Neo4j** - Graph database (ports 7474/7687 internally)
- **Rust API** - Demo web server with HTTPS
- **SSH Server** - Development access (dev mode only)
- **Claude CLI** - Pre-installed for AI-assisted coding (dev mode)

## Connecting to Services

### From Outside the Container

```bash
# Web UI
https://localhost:8443

# SSH (dev mode only)
ssh -p 2222 devuser@localhost

# Check container status
docker ps
docker logs kalisi-demo
```

### From Inside the Container (via SSH)

```bash
# Redis
redis-cli

# Neo4j Browser
# Open http://localhost:7474 in a browser (port forward if needed)
# Or use cypher-shell
cypher-shell

# Check service status
curl http://localhost:8443/api/info
```

## Port Forwarding for Remote Access

If running on a remote server, use SSH port forwarding:

```bash
# Forward web UI and Neo4j browser
ssh -L 8443:localhost:8443 -L 7474:localhost:7474 user@your-server

# Then access locally:
# https://localhost:8443 (Web UI)
# http://localhost:7474 (Neo4j Browser)
```

## Data Persistence

All data is stored in Docker volumes:
- `/data/redis` - Redis persistence files
- `/data/neo4j` - Neo4j database files
- `/data/app` - Application data

The `kalisi-demo-data` volume persists across container restarts.

## Startup Time

The container starts all services in approximately 10-15 seconds:
1. Redis starts immediately
2. Neo4j takes 8-10 seconds to initialize
3. Web server starts once all services are ready

## Troubleshooting

### Certificate Warning
The demo uses a self-signed certificate. Accept the browser warning to proceed.

### Container Won't Start
```bash
# Check logs
docker logs kalisi-demo

# Remove and recreate
docker rm -f kalisi-demo
docker run -d --name kalisi-demo ...
```

### Can't Connect via SSH
Ensure you're running in developer mode with `-e ENABLE_SSH=true` and port 2222 mapped.

### Services Not Ready
The container waits for all services before starting the web server. Check logs if startup seems stuck:
```bash
docker logs -f kalisi-demo
```

## Development Workflow

1. **SSH into the container** (dev mode):
   ```bash
   ssh -p 2222 devuser@localhost
   ```

2. **Modify code**:
   ```bash
   cd /app
   # Edit static files, modify Rust code, etc.
   ```

3. **Use Claude CLI**:
   ```bash
   claude-code
   ```

4. **Access databases**:
   ```bash
   # Redis
   redis-cli
   
   # Neo4j
   cypher-shell
   ```

## Building from Source

If you want to build the image yourself:

```bash
git clone https://github.com/glensimister/kalisi-demo
cd kalisi-demo
docker build -t kalisi-demo:custom .
```

## Security Notes

- The demo uses default passwords and no authentication for databases
- The SSH password is hardcoded (`devpass`)
- This is intended for demo/development use only
- For production use, properly secure all services

## System Requirements

- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- 4GB free disk space for the image
- 2GB RAM minimum (4GB recommended)
- Ports 8443 and optionally 2222 available

## Support

For issues or questions, please open an issue on the GitHub repository.