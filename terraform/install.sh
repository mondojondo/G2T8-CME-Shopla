#cloud-config
#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

apt update
apt install vim -y
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 22
nvm use 22 # Ensure the correct version is used
apt install git -y

folder=root/G2T8-CME-Shopla
git clone "https://github.com/mondojondo/G2T8-CME-Shopla.git" "$folder"

dir="$folder/shopla"
cd "$dir"

npm install

echo "Building the application..."
npm run build -- --skip-minify
if [ $? -ne 0 ]; then
  echo "Build failed.  Check the output for errors."
  exit 1
fi

echo "Starting the application..."
npm run start