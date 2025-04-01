#!/bin/bash
set -e

echo "🛑 Stopping LocalStack containers..."
docker-compose down -v

echo "💣 Removing LocalStack Docker volumes..."
docker volume rm $(docker volume ls -q --filter name=localstack) 2>/dev/null || true

echo "🧹 Deleting LocalStack persistent state directories..."
rm -rf volume/sg volume/th

echo "🧼 Removing Terraform state and cache..."
rm -rf .terraform terraform.tfstate terraform.tfstate.backup

echo "🚀 Starting LocalStack containers fresh..."
docker-compose up -d

echo "⏳ Waiting for LocalStack to be healthy..."

# New condition: check S3 availability as a proxy for readiness
until curl -s http://localhost:4566/_localstack/health | jq -r '.services.s3' | grep -q "available"; do
  echo "⌛ Waiting for LocalStack S3 service to be available..."
  sleep 2
done

echo "✅ LocalStack is healthy!"

echo "🧩 Re-initializing Terraform..."
tflocal init
tflocal apply -auto-approve

echo "✅ Clean restart and apply complete!"
