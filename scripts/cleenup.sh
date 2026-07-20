#!/bin/bash
# Run this manually to destroy ALL resources if something goes wrong

set -e

echo "🧹 Starting cleanup..."

# Terraform destroy
cd terraform
terraform destroy -auto-approve || echo "Terraform destroy done or no resources"

# Find and deregister any AMIs created by this pipeline
echo "🔍 Finding old AMIs..."
AMI_IDS=$(aws ec2 describe-images --owners self --filters "Name=name,Values=golden-image-*" --query 'Images[].ImageId' --output text)

if [ -n "$AMI_IDS" ]; then
  for AMI_ID in $AMI_IDS; do
    echo "Deregistering AMI: $AMI_ID"
    aws ec2 deregister-image --image-id $AMI_ID
    
    # Get associated snapshot and delete it
    SNAP_ID=$(aws ec2 describe-images --image-ids $AMI_ID --query 'Images[0].BlockDeviceMappings[0].Ebs.SnapshotId' --output text)
    if [ "$SNAP_ID" != "None" ] && [ -n "$SNAP_ID" ]; then
      echo "Deleting snapshot: $SNAP_ID"
      aws ec2 delete-snapshot --snapshot-id $SNAP_ID
    fi
  done
else
  echo "No old AMIs found."
fi

echo "✅ Cleanup complete! Your AWS account should be empty."