#!/usr/bin/env bash
# Retain the newest three Golden Image Factory AMIs.
# Default mode is dry-run. Pass --apply to deregister older AMIs.
set -Eeuo pipefail

KEEP="${KEEP_GOLDEN_AMIS:-3}"
APPLY=false

if [[ "${1:-}" == "--apply" ]]; then
  APPLY=true
elif [[ -n "${1:-}" ]]; then
  echo "Usage: $0 [--apply]" >&2
  exit 2
fi

if ! [[ "$KEEP" =~ ^[1-9][0-9]*$ ]]; then
  echo "KEEP_GOLDEN_AMIS must be a positive integer." >&2
  exit 2
fi

command -v aws >/dev/null || { echo "AWS CLI is required." >&2; exit 1; }
aws sts get-caller-identity >/dev/null

mapfile -t AMIS < <(
  aws ec2 describe-images \
    --owners self \
    --filters "Name=name,Values=golden-image-*" \
    --query 'Images | sort_by(@, &CreationDate) | reverse(@)[].ImageId' \
    --output text | tr '\t' '\n' | sed '/^$/d'
)

if (( ${#AMIS[@]} <= KEEP )); then
  echo "Found ${#AMIS[@]} matching AMI(s); nothing to remove."
  exit 0
fi

for AMI_ID in "${AMIS[@]:KEEP}"; do
  echo "Candidate for deregistration: $AMI_ID"
  if [[ "$APPLY" != true ]]; then
    continue
  fi

  # Capture snapshots before deregistration, because the AMI metadata is no
  # longer available afterwards.
  mapfile -t SNAPSHOTS < <(
    aws ec2 describe-images --image-ids "$AMI_ID" \
      --query 'Images[0].BlockDeviceMappings[?Ebs.SnapshotId!=null].Ebs.SnapshotId' \
      --output text | tr '\t' '\n' | sed '/^$/d'
  )

  aws ec2 deregister-image --image-id "$AMI_ID"

  for SNAPSHOT_ID in "${SNAPSHOTS[@]}"; do
    # Never delete a snapshot still referenced by another owned AMI.
    mapfile -t REFERENCES < <(
      aws ec2 describe-images --owners self \
        --filters "Name=block-device-mapping.snapshot-id,Values=$SNAPSHOT_ID" \
        --query 'Images[].ImageId' --output text | tr '\t' '\n' | sed '/^$/d'
    )
    if (( ${#REFERENCES[@]} == 0 )); then
      echo "Deleting unreferenced snapshot $SNAPSHOT_ID"
      aws ec2 delete-snapshot --snapshot-id "$SNAPSHOT_ID"
    else
      echo "Keeping snapshot $SNAPSHOT_ID; it is still referenced by an AMI."
    fi
  done
done

if [[ "$APPLY" != true ]]; then
  echo "Dry-run only. Re-run with --apply to deregister AMIs older than the newest $KEEP."
else
  echo "AMI retention cleanup completed."
fi
