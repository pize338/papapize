#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: list-fsx-backups.sh AWSprofileName "
  echo "./list-fsx-backups.sh AWSprofileName"
  exit 1
fi

AWS_PROFILE="$1"
output_file="fsx-backups-$AWS_PROFILE.csv"

# Get backup list and write output to backups-$AWS_PROFILE.csv
echo "BackupId,Type" > "$output_file"

aws fsx describe-backups \
--query 'Backups[*].[BackupId,Type]' \
--output json \
--profile "$AWS_PROFILE" | jq -r '.[] | [.[] | tostring] | @csv' | while read -r row; do

  # Write the output to the file
  echo "$row" >> "$output_file"

  # Print a message indicating the results were written to the file
  #echo "Backup $BACKUP_ID written to $output_file"
done

# Print a final message indicating the script has completed
echo "Script completed successfully. Output written to $output_file"
