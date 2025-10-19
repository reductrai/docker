#!/bin/bash
set -e

# Update Docker Hub Repository Descriptions
# This script updates the full description for all ReductrAI images on Docker Hub

echo "📝 Updating Docker Hub Repository Descriptions"
echo "=============================================="

# Check if README exists
if [ ! -f "README.md" ]; then
    echo "❌ Error: README.md not found"
    exit 1
fi

# Docker Hub username
DOCKERHUB_USERNAME="reductrai"

# Read README content and escape for JSON
README_CONTENT=$(cat README.md | jq -Rs .)

echo ""
echo "🔐 Authenticating with Docker Hub..."

# Check if password is provided
if [ -z "$DOCKERHUB_PASSWORD" ]; then
    echo "❌ Error: DOCKERHUB_PASSWORD environment variable not set"
    echo "Usage: DOCKERHUB_PASSWORD='your-password' ./update-dockerhub-readmes.sh"
    exit 1
fi

# Get Docker Hub token
TOKEN_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"$DOCKERHUB_USERNAME\", \"password\": \"$DOCKERHUB_PASSWORD\"}" \
    https://hub.docker.com/v2/users/login/)

echo ""

TOKEN=$(echo $TOKEN_RESPONSE | jq -r .token)

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo "❌ Authentication failed"
    exit 1
fi

echo "✅ Authenticated successfully"
echo ""

# List of repositories to update
REPOS=("proxy" "dashboard" "ai-query" "ollama")

# Update each repository
for REPO in "${REPOS[@]}"; do
    echo "📤 Updating $DOCKERHUB_USERNAME/$REPO..."

    RESPONSE=$(curl -s -X PATCH \
        -H "Authorization: JWT $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"full_description\": $README_CONTENT}" \
        "https://hub.docker.com/v2/repositories/$DOCKERHUB_USERNAME/$REPO/")

    if echo "$RESPONSE" | jq -e .name > /dev/null 2>&1; then
        echo "✅ $REPO description updated"
    else
        echo "❌ Failed to update $REPO"
        echo "$RESPONSE" | jq .
    fi
    echo ""
done

echo "=============================================="
echo "✨ Docker Hub Descriptions Updated!"
echo "=============================================="
echo ""
echo "View updated repositories:"
echo "  - https://hub.docker.com/r/$DOCKERHUB_USERNAME/proxy"
echo "  - https://hub.docker.com/r/$DOCKERHUB_USERNAME/dashboard"
echo "  - https://hub.docker.com/r/$DOCKERHUB_USERNAME/ai-query"
echo "  - https://hub.docker.com/r/$DOCKERHUB_USERNAME/ollama"
echo ""
