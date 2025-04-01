#!/bin/bash

echo "🔍 Verifying LocalStack Resources..."

ENDPOINT_SG="--endpoint-url=http://localhost:4566"
ENDPOINT_TH="--endpoint-url=http://localhost:4567"

### Singapore
echo -e "\n🌐 VPCs (Singapore)"
awslocal $ENDPOINT_SG ec2 describe-vpcs --query "Vpcs[*].VpcId"

echo -e "\n📦 S3 Buckets (Singapore)"
awslocal $ENDPOINT_SG s3api list-buckets --query "Buckets[*].Name"

echo -e "\n🛠️  Subnets (Singapore)"
awslocal $ENDPOINT_SG ec2 describe-subnets --query "Subnets[*].{ID:SubnetId, AZ:AvailabilityZone}"

echo -e "\n🖥️  ALBs (Singapore)"
awslocal $ENDPOINT_SG elbv2 describe-load-balancers --query "LoadBalancers[*].DNSName"

echo -e "\n💾 Aurora Clusters (Singapore)"
awslocal $ENDPOINT_SG rds describe-db-clusters --query "DBClusters[*].DBClusterIdentifier"

### Thailand
echo -e "\n🌐 VPCs (Thailand)"
awslocal $ENDPOINT_TH ec2 describe-vpcs --query "Vpcs[*].VpcId"

echo -e "\n📦 S3 Buckets (Thailand)"
awslocal $ENDPOINT_TH s3api list-buckets --query "Buckets[*].Name"

echo -e "\n🛠️  Subnets (Thailand)"
awslocal $ENDPOINT_TH ec2 describe-subnets --query "Subnets[*].{ID:SubnetId, AZ:AvailabilityZone}"

echo -e "\n🖥️  ALBs (Thailand)"
awslocal $ENDPOINT_TH elbv2 describe-load-balancers --query "LoadBalancers[*].DNSName"

### Shared
echo -e "\n🌍 CloudFront Distributions (All Regions)"
awslocal $ENDPOINT_SG cloudfront list-distributions --query "DistributionList.Items[*].{Domain:DomainName, Origin:Origins.Items[0].DomainName}"

echo -e "\n🌐 Route 53 Zones"
awslocal $ENDPOINT_SG route53 list-hosted-zones --query "HostedZones[*].Name"

echo -e "\n✅ All done!"
