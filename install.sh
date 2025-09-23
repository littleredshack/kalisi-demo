#!/bin/bash

echo "
╔═══════════════════════════════════╗
║     Kalisi Demo Installer         ║
╚═══════════════════════════════════╝
"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed!"
    echo ""
    
    # Detect OS
    OS="unknown"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    fi
    
    echo "Would you like me to help install Docker? (y/n)"
    if [ -t 0 ]; then
        read -p "Enter choice [y]: " install_docker
    else
        echo "Enter choice [y]: " >&2
        read install_docker < /dev/tty
    fi
    install_docker=${install_docker:-y}
    
    if [[ "$install_docker" == "y" ]] || [[ "$install_docker" == "Y" ]]; then
        case $OS in
            macos)
                echo "🍎 Opening Docker Desktop download page for macOS..."
                open "https://www.docker.com/products/docker-desktop/"
                echo ""
                echo "Please:"
                echo "1. Download Docker Desktop for Mac"
                echo "2. Open the .dmg file"
                echo "3. Drag Docker to Applications"
                echo "4. Start Docker Desktop"
                echo "5. Wait for the whale icon in your menu bar"
                echo "6. Re-run this installer"
                ;;
            linux)
                echo "🐧 Installing Docker on Linux..."
                echo "This requires sudo access."
                curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
                sh /tmp/get-docker.sh
                sudo usermod -aG docker $USER
                echo ""
                echo "✅ Docker installed!"
                echo "⚠️  You need to logout and login again for group changes to take effect."
                echo "   Or run: newgrp docker"
                ;;
            windows)
                echo "🪟 Opening Docker Desktop download page for Windows..."
                start "https://www.docker.com/products/docker-desktop/"
                echo ""
                echo "Please:"
                echo "1. Download Docker Desktop for Windows"
                echo "2. Run the installer"
                echo "3. Follow the setup wizard"
                echo "4. Start Docker Desktop"
                echo "5. Re-run this installer"
                ;;
            *)
                echo "❓ Could not detect OS. Please install Docker manually:"
                echo "   https://www.docker.com/products/docker-desktop"
                ;;
        esac
    else
        echo ""
        echo "Please install Docker manually and re-run this installer."
        echo "Visit: https://www.docker.com/products/docker-desktop"
    fi
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is installed but not running!"
    echo ""
    echo "Please start Docker Desktop:"
    echo "🍎 macOS: Click the Docker whale icon in your menu bar"
    echo "🪟 Windows: Start Docker Desktop from Start Menu"
    echo "🐧 Linux: Run: sudo systemctl start docker"
    echo ""
    exit 1
fi

echo "Choose your installation mode:"
echo "1) Simple mode (just the web UI)"
echo "2) Developer mode (web UI + SSH access)"
echo ""

# Handle piped input by reading from tty if available
if [ -t 0 ]; then
    read -p "Enter choice [1]: " choice
else
    echo "Enter choice [1]: " >&2
    read choice < /dev/tty
fi

# Set ports and environment based on choice
if [ "$choice" = "2" ]; then
    PORTS="-p 8443:8443 -p 2222:22"
    ENV_VARS="-e ENABLE_SSH=true"
    MODE="Developer"
    echo ""
    echo "🛠️  Developer mode selected"
else
    PORTS="-p 8443:8443"
    ENV_VARS=""
    MODE="Simple"
    echo ""
    echo "📦 Simple mode selected"
fi

# Pull the image
echo ""
echo "📥 Downloading Kalisi Demo..."
docker pull ghcr.io/littleredshack/kalisi-demo:v1.2-multiarch

# Stop existing container if any
docker stop kalisi-demo 2>/dev/null || true
docker rm kalisi-demo 2>/dev/null || true

# Run the container
echo "🚀 Starting Kalisi Demo..."
docker run -d \
    --name kalisi-demo \
    $PORTS \
    $ENV_VARS \
    -v kalisi-demo-data:/data \
    --restart unless-stopped \
    ghcr.io/littleredshack/kalisi-demo:v1.2-multiarch

# Wait for startup
echo "⏳ Waiting for services to start..."
sleep 10

# Check if running
if docker ps | grep -q kalisi-demo; then
    echo ""
    echo "✅ Kalisi Demo is running!"
    echo ""
    echo "🌐 Open your browser to: https://localhost:8443"
    echo "   (You may see a certificate warning - that's normal for the demo)"
    
    if [ "$MODE" = "Developer" ]; then
        echo ""
        echo "🔧 SSH Access:"
        echo "   ssh -p 2222 devuser@localhost"
        echo "   Password: devpass"
    fi
    
    echo ""
    echo "📊 To see logs: docker logs -f kalisi-demo"
    echo "🛑 To stop: docker stop kalisi-demo"
    echo ""
else
    echo "❌ Failed to start Kalisi Demo"
    echo "Check logs with: docker logs kalisi-demo"
    exit 1
fi