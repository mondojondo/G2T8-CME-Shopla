#cloud-config
#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

apt update
apt install vim -y

# Install CloudWatch agent
echo "Installing CloudWatch agent..."
apt install -y wget
wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm ./amazon-cloudwatch-agent.deb

# Create CloudWatch agent configuration file
echo "Configuring CloudWatch agent..."
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "agent": {
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/root/G2T8-CME-Shopla/shopla/logs/app.log",
            "log_group_name": "/aws/ec2/shopla",
            "log_stream_name": "{instance_id}/application.log",
            "retention_in_days": 30
          },
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/ec2/shopla",
            "log_stream_name": "{instance_id}/syslog",
            "retention_in_days": 30
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"]
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "resources": ["/"]
      }
    }
  }
}
EOF

# Start CloudWatch agent and enable on boot
echo "Starting CloudWatch agent..."
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent
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

# Create application log directory
mkdir -p logs

echo "Starting the application..."
npm run start > logs/app.log 2>&1 &

# Wait for CloudWatch agent to properly collect initial logs
echo "CloudWatch agent is now collecting logs from the application"
