#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: list-s3-buckets.sh AWSprofileName "
  echo "./list-s3-buckets.sh AWSprofileName"
  exit 1
fi

AWS_PROFILE="$1"
output_file="s3-buckets-$AWS_PROFILE.csv"

# Get bucket list and write output to buckets-$AWS_PROFILE.csv
echo "BucketName,CreatedDate" > "$output_file"

aws s3api list-buckets \
--query 'Buckets[*].[Name,CreationDate]' \
--output json \
--profile "$AWS_PROFILE" | jq -r '.[] | [.[] | tostring] | @csv' | while read -r row; do

  # Write the output to the file
  echo "$row" >> "$output_file"

  # Print a message indicating the results were written to the file
  echo "Bucket $BUCKET_NAME written to $output_file"
done

# Print a final message indicating the script has completed
echo "Script completed successfully. Output written to $output_file"
