#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: get-snapshot-info.sh AWSprofileName "
  echo "./get-snapshot-info.sh AWSprofileName"
  exit 1
fi

AWS_PROFILE="$1"
output_file="snapshots-$AWS_PROFILE.csv"

# Get snapshot info and write output to snapshots-$AWS_PROFILE.csv
echo "SnapshotId,VolumeSize(GiB),VolumeId,StartTime,Description,SnapshotStatus" > "$output_file"

aws ec2 describe-snapshots \
--owner-ids self \
--query 'Snapshots[*].[SnapshotId,VolumeSize,VolumeId,StartTime,Description,State]' \
--output json \
--profile "$AWS_PROFILE" | jq -r '.[] | [.[] | tostring] | @csv' | while read -r row; do

  # Write the output to the file
  echo "$row" >> "$output_file"

  # Print a message indicating the results were written to the file
  echo "Snapshot $SNAP_ID written to $output_file"
done

# Print a final message indicating the script has completed
echo "Script completed successfully. Output written to $output_file"
