#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
KEEP="${KEEP_GOLDEN_AMIS:-3}"
APPLY="false"

usage() {
  cat <<'EOF'
Usage: AWS_REGION=us-east-1 KEEP_GOLDEN_AMIS=3 ./scripts/cleanup.sh [--apply]

Default mode is dry-run. --apply deregisters old AMIs tagged ManagedBy=GoldenImageFactory
and deletes their associated EBS snapshots after successful deregistration.
This script does not run terraform destroy and never deletes untagged images.
EOF
}

case "${1:-}" in
  "") ;;
  --apply) APPLY="true" ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

if ! [[ "$KEEP" =~ ^[0-9]+$ ]] || (( KEEP < 1 )); then
  echo "KEEP_GOLDEN_AMIS must be a positive integer." >&2
  exit 2
fi

command -v aws >/dev/null || { echo "AWS CLI is required." >&2; exit 1; }

ami_ids_text="$(aws ec2 describe-images \
  --region "$REGION" \
  --owners self \
  --filters "Name=name,Values=golden-image-*" "Name=tag:ManagedBy,Values=GoldenImageFactory" \
  --query "Images | sort_by(@, &CreationDate) | reverse(@) | [${KEEP}:].ImageId" \
  --output text)"
mapfile -t ami_ids < <(printf '%s\n' "$ami_ids_text" | tr '\t' '\n' | sed '/^None$/d;/^$/d')

if (( ${#ami_ids[@]} == 0 )); then
  echo "No managed Golden AMIs exceed retention count ${KEEP}."
  exit 0
fi

for ami_id in "${ami_ids[@]}"; do
  snapshot_ids_text="$(aws ec2 describe-images --region "$REGION" --image-ids "$ami_id" \
    --query 'Images[0].BlockDeviceMappings[?Ebs.SnapshotId!=null].Ebs.SnapshotId' \
    --output text)"
  mapfile -t snapshot_ids < <(printf '%s\n' "$snapshot_ids_text" | tr '\t' '\n' | sed '/^None$/d;/^$/d')

  if [[ "$APPLY" != "true" ]]; then
    printf 'DRY RUN: would deregister %s and delete snapshots: %s\n' "$ami_id" "${snapshot_ids[*]:-none}"
    continue
  fi

  echo "Deregistering $ami_id"
  aws ec2 deregister-image --region "$REGION" --image-id "$ami_id"
  for snapshot_id in "${snapshot_ids[@]}"; do
    echo "Deleting $snapshot_id"
    aws ec2 delete-snapshot --region "$REGION" --snapshot-id "$snapshot_id"
  done
done

[[ "$APPLY" == "true" ]] || echo "Dry-run only. Re-run with --apply to perform the cleanup."
