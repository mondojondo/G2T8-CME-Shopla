#!/bin/bash
set -e

# Update and install dependencies
apt-get update
apt-get install -y vim git curl

# Install NVM and Node.js
export NVM_DIR="$HOME/.nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 22
nvm use 22

# Install PM2 globally
npm install -g pm2

# Clone and setup application
cd /home/ubuntu
if [ ! -d "G2T8-CME-Shopla" ]; then
    git clone "https://github.com/mondojondo/G2T8-CME-Shopla.git"
fi

cd G2T8-CME-Shopla/shopla
npm install

echo "Building the application..."
npm run build -- --skip-minify || {
    echo "Build failed. Check the output for errors."
    exit 1
}

echo "Starting the application with PM2..."
pm2 start npm --name "shopla" -- start || {
    echo "Failed to start application with PM2"
    exit 1
}

# Save PM2 process list and configure to start on boot
pm2 save
pm2 startup
