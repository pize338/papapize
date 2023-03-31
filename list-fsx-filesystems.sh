#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: list-fsx-filesystems.sh AWSprofileName "
  echo "./list-fsx-filesystems.sh AWSprofileName"
  exit 1
fi

AWS_PROFILE="$1"
output_file="fsx-filesystems-$AWS_PROFILE.csv"

# Get filesystem list and write output to filesystems-$AWS_PROFILE.csv
echo "FileSystemId,FileSystemType,DeploymentType,StorageType,StorageCapacityGiB" > "$output_file"

aws fsx describe-file-systems \
--query 'FileSystems[*].[FileSystemId,FileSystemType,WindowsConfiguration.DeploymentType,StorageType,StorageCapacity]' \
--output json \
--profile "$AWS_PROFILE" | jq -r '.[] | @csv' | while read -r row; do

  # Write the output to the file
  echo "$row" >> "$output_file"

  # Print a message indicating the results were written to the file
  #FILESYSTEM_ID=$(echo "$row" | cut -d',' -f1)
  #echo "FileSystem $FILESYSTEM_ID written to $output_file"
done

# Print a final message indicating the script has completed
echo "Script completed successfully. Output written to $output_file"
