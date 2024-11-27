#!/bin/bash
# Update package lists for available software repositories.
sudo apt update -y

# Download and add Adoptium's GPG public key to the keyring.
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc

# Add Adoptium's repository to the system's list of package sources.
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list

# Update package lists again to include Adoptium's repository.
sudo apt update -y

# Install OpenJDK 17.
sudo apt install openjdk-17-jdk -y

# Check the installed Java version.
/usr/bin/java --version

# Download and add Jenkins' GPG public key to the keyring.
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins' repository to the system's list of package sources.
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package lists again to include Jenkins' repository.
sudo apt-get update -y

# Install Jenkins.
sudo apt-get install jenkins -y

# Enable and start the Jenkins service.
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Check the status of the Jenkins service.
sudo systemctl status jenkins