#!/bin/bash

# Enable debug mode
# set -x

if [ $# -ne 1 ]; then
  echo "Usage: script.sh arg1 "
  echo "./script profileName"
  exit 1
fi

AWS_PROFILE=$1
FILENAME="$AWS_PROFILE-ec2list.txt"
OUTPUT_FILE="$AWS_PROFILE-metrics.csv"
CW_CUSTOM_NAMESPACE="CWAgent"

aws ec2 describe-instances --profile $AWS_PROFILE --query 'Reservations[*].Instances[*].[InstanceId]' --output text > $FILENAME

#Write Header to a CSV file
echo "instanceState,instanceName,platform,%CPUUtilization,%MemUsed,Memory % Committed Bytes In Use,DiskUsed/GB,DiskFree/GB,DiskTotal/GB,LogicalDisk % Free Space,NetworkIn/Bytes,NetworkOut/Bytes,%SLA System Uptime" > $OUTPUT_FILE

while read -r line
do

# Set the instance ID and output file name
INSTANCE_ID="$line"
echo $INSTANCE_ID

# Get the average CPU utilization for the instance over the past 30 Days
CPU_UTILIZATION=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 2592000 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
	--query 'Datapoints[0].Average')

# Get the average Memory used percent for the linux instance over the past 30 days
MEM_USED_LINUX=$(aws cloudwatch get-metric-statistics \
    --namespace CWAgent \
    --metric-name mem_used_percent \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 2592000 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
	--query 'Datapoints[0].Average')
	
# Get the average Memory used percent for the window instance over the past 30 days
MEM_USED_WINDOW=$(aws cloudwatch get-metric-statistics \
    --namespace CWAgent \
    --metric-name "Memory % Committed Bytes In Use" \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 2592000 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
	--query 'Datapoints[0].Average')

# Get the average Disk used for the linux instance over the past 30 Days
DISK_USED=$(aws cloudwatch get-metric-statistics \
    --namespace $CW_CUSTOM_NAMESPACE \
    --metric-name disk_used \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 2592000 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
	--query 'Datapoints[0].Average')

# Get the average Disk Free for the linux instance over the past 30 Days
DISK_FREE_LINUX=$(aws cloudwatch get-metric-statistics \
    --namespace $CW_CUSTOM_NAMESPACE \
    --metric-name disk_free \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 2592000 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
	--query 'Datapoints[0].Average')

# Get the average Disk total for the linux instance over the past 30 Days
DISK_TOTAL=$(aws cloudwatch get-metric-statistics \
    --namespace $CW_CUSTOM_NAMESPACE \
    --metric-name disk_total \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 2592000 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
	--query 'Datapoints[0].Average')
	
# Get the average Disk Free for the window instance over the past 30 Days
DISK_FREE_WINDOW=$(aws cloudwatch get-metric-statistics \
    --namespace $CW_CUSTOM_NAMESPACE \
    --metric-name "LogicalDisk % Free Space" \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 2592000 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
	--query 'Datapoints[0].Average')

# Get the average NetworkIn for the instance over the past 30 Days
NETWORK_IN=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name NetworkIn \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 2592000 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
	--query 'Datapoints[0].Average')

# Get the average NetworkOut for the instance over the past 30 Days
NETWORK_OUT=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name NetworkOut \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 2592000 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
	--query 'Datapoints[0].Average')
	
# Get the SLA_UPTIME for the instance over the past 30 Days
DATA=$(aws cloudwatch get-metric-data \
  --metric-data-queries '[
    {
      "Id": "m1",
      "MetricStat": {
        "Metric": {
          "Namespace": "'"AWS/EC2"'",
          "MetricName": "'"StatusCheckFailed_System"'",
          "Dimensions": [
            {
              "Name": "InstanceId",
              "Value": "'"$INSTANCE_ID"'"
            }
          ]
        },
        "Period": 300,
        "Stat": "Maximum"
      },
      "ReturnData": true
    }
  ]' \
  --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --scan-by 'TimestampDescending' \
  --query 'MetricDataResults[0].Values[]' \
  --profile "$AWS_PROFILE" \
  --output 'text')
  
# Calculate the SLA percentage
SUM=$(echo $DATA | tr ' ' '\n' | awk '{sum += $1} END {print sum}')
TOTAL=$(echo $DATA | tr ' ' '\n' | wc -l)
SLA=$(echo "scale=2; (100 * ($SUM * 5 - 43200)) / 43200" | bc | awk '{print ($1 < 0) ? -$1 : $1}' )

# Get the instance name
INSTANCE_NAME=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value, State.Name]" \
    --profile $AWS_PROFILE \
    --output text \
    | tr '\n' ',')
	
PLATFORM=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].[Platform]" \
    --profile $AWS_PROFILE \
    --output text)

# Get EC2 instances with name and status
# INSTANCE_STATE=$(aws ec2 describe-instances \
#     --query "Reservations[*].Instances[*].[State.Name]" \
#     --profile ${AWS_PROFILE} \
#     --output text)

# Convert bytes to gigabytes
DISK_USED_GB=$(echo "scale=2; $DISK_USED/1024/1024/1024" | bc)
DISK_FREE_GB=$(echo "scale=2; $DISK_FREE_LINUX/1024/1024/1024" | bc)
DISK_TOTAL_GB=$(echo "scale=2; $DISK_TOTAL/1024/1024/1024" | bc)


# Write the results to a CSV file
echo "${INSTANCE_NAME%?},$PLATFORM,$CPU_UTILIZATION,$MEM_USED_LINUX,$MEM_USED_WINDOW,$DISK_USED_GB,$DISK_FREE_GB,$DISK_TOTAL_GB,$DISK_FREE_WINDOW,$NETWORK_IN,$NETWORK_OUT,$SLA%" >> $OUTPUT_FILE

# Print a message indicating the results were written to the file
echo "Metrics for instance $INSTANCE_ID ($INSTANCE_NAME) written to $OUTPUT_FILE"

done < "$FILENAME"

# Write Header to a CSV file
# sed -i '1i instanceState,instanceName,%CPUUtilization,%MemUsed,DiskUsed/GB,DiskFree/GB,DiskTotal/GB,NetworkIn/Bytes,NetworkOut/Bytes' $OUTPUT_FILE
