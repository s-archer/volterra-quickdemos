#!/bin/bash


# Prevent "stdin is not a tty" errors
export DEBIAN_FRONTEND=noninteractive

# Redirect stderr to stdout and append all output to a log file
exec 2>&1
exec > >(tee /var/log/user-data.log)

# Exit on any error
set -e

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi


echo "Creating Docker network..."
docker network create ollama-network || true

echo "Pulling and running Ollama..."
docker pull ollama/ollama:latest
docker run -d --gpus=all --network ollama-network \
    --name ollama \
    -v ollama:/root/.ollama \
    -p 11434:11434 \
    ollama/ollama

echo "Waiting for Ollama container to initialize (30 seconds)..."
sleep 30

echo "Pulling llama3.1:8b model..."
docker exec ollama ollama pull llama3.1:8b

echo "Pulling mistral:7b model..."
docker exec ollama ollama pull mistral:7b

echo "Pulling and running OpenWebUI..."
docker pull ghcr.io/open-webui/open-webui:main
docker run -d --network ollama-network \
    --name open-webui \
    -p 8080:8080 \
    -e OLLAMA_BASE_URL=http://ollama:11434/ \
    -e WEBUI_AUTH=False \
    ghcr.io/open-webui/open-webui:main

echo "Setup complete!"
echo "OpenWebUI is available at http://your-instance-ip:8080"
echo "Please wait a few minutes for the Llama model to complete downloading"
echo "You may need to log out and back in for docker commands to work as ec2-user"