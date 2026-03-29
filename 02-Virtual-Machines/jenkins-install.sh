#!/bin/bash

------------------------------------------
# Script: Install Jenkins using WAR method
# Author: Md Asadul Howlader
# VM: Azure Ubuntu 24.04
# Date: 29/03/2026
# Version: 0.001
------------------------------------------

set -e
set -o pipefail
set -x

# Install Java 17 (Jenkins requires it)
sudo apt update -y
sudo apt install openjdk-17-jre -y

# Verify Java installed
java -version

# Download Jenkins WAR file ( Do every command separately)

sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
#
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
#
sudo apt update
#
sudo apt install jenkins

# Run Jenkins on which port
ps -ef | grep jenkins

# Check Status
sudo systemctl status jenkins
echo "Jenkins running at http://20.250.17.39:4000

