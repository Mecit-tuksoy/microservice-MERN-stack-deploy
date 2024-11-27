#!/bin/bash
# Update the package lists for available software repositories to ensure that the system has the latest information about available packages.
sudo apt-get update

# Install Docker Engine on the system.
sudo apt-get install docker.io -y

# Add the current user to the "docker" group to allow them to run Docker commands without sudo.
sudo usermod -aG docker $USER

# Add the "jenkins" user to the "docker" group to allow Jenkins to run Docker commands.
sudo usermod -aG docker jenkins

# Activate the changes to the group membership.
newgrp docker

# Set permissions for Docker socket to allow access.
sudo chmod 777 /var/run/docker.sock

# Enable Docker to start on system boot.
sudo systemctl enable docker

# Start the Docker service.
sudo systemctl start docker

# Check the status of the Docker service to ensure it is running.
sudo systemctl status docker