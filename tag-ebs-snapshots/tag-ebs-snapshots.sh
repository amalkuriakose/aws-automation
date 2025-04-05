#!/bin/zsh

# AWS CLI must be configured with appropriate credentials and region.

# Input variables

VOLUME_ID="vol-123xxx"
TAG_KEY="key"
TAG_VALUE="value"

# Check if required arguments are provided
if [ -z "$VOLUME_ID" ] || [ -z "$TAG_KEY" ] || [ -z "$TAG_VALUE" ]; then
  echo "Usage: $0 <volume_id> <tag_key> <tag_value>"
  exit 1
fi

# Fetch snapshot IDs associated with the volume
SNAPSHOT_IDS=$(aws ec2 describe-snapshots \
  --filters "Name=volume-id,Values=$VOLUME_ID" \
  --query "Snapshots[*].SnapshotId" \
  --profile "sandbox" \
  --region "eu-west-1" \
  --output json)

# Check if any snapshots were found
if [ -z "$SNAPSHOT_IDS" ]; then
  echo "No snapshots found for volume ID: $VOLUME_ID"
  exit 1
fi

# Convert JSON array to a bash array
SNAPSHOT_IDS_ARRAY=($(echo "$SNAPSHOT_IDS" | jq -r '.[ ]'))

#Loop through each snapshot ID and add the tag
for SNAPSHOT_ID in $SNAPSHOT_IDS_ARRAY; do
  if [ -n "$SNAPSHOT_ID" ]; then #prevent empty lines from being processed
    echo "Adding tag $TAG_KEY:$TAG_VALUE to snapshot: $SNAPSHOT_ID"
    aws ec2 create-tags \
      --resources "$SNAPSHOT_ID" \
      --tags "Key=$TAG_KEY,Value=$TAG_VALUE" \
      --profile "sandbox" \
      --region "eu-west-1"
    if [ $? -ne 0 ]; then
      echo "Failed to add tag to snapshot: $SNAPSHOT_ID"
    else
      echo "Tag successfully added to snapshot: $SNAPSHOT_ID"
    fi
  fi
done

echo "Script completed."
exit 0