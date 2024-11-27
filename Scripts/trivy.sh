#!/bin/bash
# Install necessary packages required for setting up repositories and downloading packages in Debian-based systems.
sudo apt-get install wget apt-transport-https gnupg lsb-release -y

# Download the GPG public key used to sign Trivy packages, import it into the system's keyring, and store it securely.
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

# Add the Trivy repository to the system's list of package sources.
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list

# Update the package lists for available software repositories to ensure that the system has the latest information about available packages.
sudo apt-get update

# Install Trivy from the configured repository.
sudo apt-get install trivy -y