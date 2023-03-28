#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: get-ebs-info.sh AWSprofileName "
  echo "./get-ebs-info.sh AWSprofileName"
  exit 1
fi

AWS_PROFILE="$1"
output_file="ebs-volumes-$AWS_PROFILE.csv"

# Get EBS volume info and write output to ebs-volumes-$AWS_PROFILE.csv
echo "VolumeId,Name,Size(GiB),VolumeType,Iops,VolumeState,AvailabilityZone,InstanceId,AttachmentState" > "$output_file"

aws ec2 describe-volumes \
--query 'Volumes[*].[VolumeId,Tags[?Key==`Name`]|[0].Value,Size,VolumeType,Iops,State,AvailabilityZone,Attachments[0].InstanceId,Attachments[0].State]' \
--output json \
--profile "$AWS_PROFILE" | jq -r '.[] | [.[] | tostring] | @csv' | while read -r row; do

  # Write the output to the file
  echo "$row" >> "$output_file"

  # Print a message indicating the results were written to the file
  echo "EBS volume $VOL_ID written to $output_file"
done

# Print a final message indicating the script has completed
echo "Script completed successfully. Output written to $output_file"
