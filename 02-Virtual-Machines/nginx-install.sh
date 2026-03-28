#!/bin/bash

#-----------------------------
# Author: Md Asadul Howlader
# Date: 28/03/2026
# VM: Ubuntu 24.04
# Script: Install and configure NGINX
#-----------------------------

set -e 
set -o pipefail

# Update System
sudo apt update -y


# Install NGINX
sudo apt install nginx -y

# Start and Enable NGINX
sudo systemctl start nginx 
sudo systemctl enable nginx

# Status check 
sudo systemctl status nginx

echo "Nginx installed successfully"
echo "Access it at: http://10.10.11"

