#!/bin/bash

echo "
╔═══════════════════════════════════════════════════╗
║   Push Kalisi Demo to GitHub Container Registry   ║
╚═══════════════════════════════════════════════════╝
"

# Check if we have the image
if ! docker images | grep -q "kalisi-demo.*latest"; then
    echo "❌ kalisi-demo:latest image not found. Please build it first."
    exit 1
fi

echo "To push to GitHub Container Registry, you need a Personal Access Token (PAT) with 'write:packages' permission."
echo ""
echo "Steps to create one:"
echo "1. Go to https://github.com/settings/tokens/new"
echo "2. Give it a name like 'kalisi-demo-ghcr'"
echo "3. Select expiration (90 days is fine)"
echo "4. Check these scopes:"
echo "   ✓ write:packages (to push images)"
echo "   ✓ read:packages (to pull images)"
echo "   ✓ delete:packages (optional, to manage images)"
echo "5. Click 'Generate token' and copy it"
echo ""
read -p "Enter your GitHub username: " GITHUB_USER
read -s -p "Enter your GitHub PAT (hidden): " GITHUB_TOKEN
echo ""

# Login to GitHub Container Registry
echo ""
echo "🔐 Logging in to ghcr.io..."
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USER --password-stdin

if [ $? -ne 0 ]; then
    echo "❌ Login failed. Please check your credentials."
    exit 1
fi

echo "✅ Login successful!"
echo ""

# Tag the images
IMAGE_NAME="ghcr.io/$GITHUB_USER/kalisi-demo"
echo "🏷️  Tagging images..."
docker tag kalisi-demo:latest $IMAGE_NAME:latest
docker tag kalisi-demo:latest $IMAGE_NAME:v1.0

# Push to registry
echo ""
echo "📤 Pushing to GitHub Container Registry..."
echo "This may take a few minutes depending on your connection speed..."
docker push $IMAGE_NAME:latest
docker push $IMAGE_NAME:v1.0

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed to ghcr.io!"
    echo ""
    echo "Your image is now available at:"
    echo "  $IMAGE_NAME:latest"
    echo "  $IMAGE_NAME:v1.0"
    echo ""
    echo "To make it public (so others can pull without auth):"
    echo "1. Go to https://github.com/$GITHUB_USER?tab=packages"
    echo "2. Click on 'kalisi-demo'"
    echo "3. Click 'Package settings'"
    echo "4. Scroll down to 'Danger Zone'"
    echo "5. Click 'Change visibility' and make it public"
    echo ""
    echo "To pull on your Mac:"
    echo "  docker pull $IMAGE_NAME:latest"
else
    echo "❌ Push failed. Please check the error messages above."
    exit 1
fi