import boto3
import json
import csv
from datetime import datetime, timedelta
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication

session = boto3.Session(profile_name='sisthai01')

def convert_json(data):
    json_object = json.dumps(data,indent=2) 
    return json_object

# Function print to .CSV
def write_to_csv(time_date,account_id,cus_name,cost_now,cost_avg,filename,columns):
    with open(filename, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["AWS Account cost usage over average"])
        writer.writerow(["Date",time_date])
        writer.writerow([])
        writer.writerow(columns)
        writer.writerows(zip(account_id,cus_name,cost_now,cost_avg))

def send_email(sender, receivers, subject, message, smtp_server, smtp_port, attachment_path=None):
    try:
        msg = MIMEMultipart()
        msg['From'] = sender
        msg['To'] = ', '.join(receivers)
        msg['Subject'] = subject

        body = MIMEText(message, 'plain')
        msg.attach(body)

        if attachment_path:
            attachment_name = os.path.basename(attachment_path)  # Get only the filename
            with open(attachment_path, 'rb') as attachment:
                part = MIMEApplication(attachment.read(), Name=attachment_name)
                part['Content-Disposition'] = f'attachment; filename="{attachment_name}"'
                msg.attach(part)

        smtpObj = smtplib.SMTP(smtp_server, smtp_port)
        smtpObj.sendmail(sender, receivers, msg.as_string())
        smtpObj.quit()
        
        print("Successfully sent email")
    except Exception as ex:
        print("Error: unable to send email")
        print(ex)

# Set your email details
sender = 'aws_sisthai01_alert@siscloudservices.com'
receivers = ['aws.masterpayer01@sisthai.com','chompoonik@sisthai.com']
subject = '[Action-Require] Alert cost anomaly for sisthai01'
smtp_server = '10.2.120.14'
smtp_port = 25

# Specify the columns
column_names = ['Account ID','Customer Name','Date cost (USD)','Avg cost of summary cost (USD)']
# Specify the filename
output_filename = f'/home/api-vm/aws_cost_report/Report_cost over average.csv'

# Calculate the start and end dates
yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')
today = datetime.now().strftime('%Y-%m-%d')
days_month_start = (datetime.now() - timedelta(days=31)).strftime('%Y-%m-%d')

def print_result(data):
    for account_id, value in data.items():
        #description = data['description']
        #start = data['time']
        price = value['amount']
        print(f"Account id: {account_id}, Total Amount: {price:.2f} USD")

client = boto3.client('ce')
response_now = client.get_cost_and_usage(
    TimePeriod={
        'Start': yesterday,
        'End': today
    },
    Granularity='DAILY',
    Filter={
        'Not': {
            'Dimensions': {
            'Key': 'RECORD_TYPE',
            'Values': [
                'Credit', 'Distributor Discount', 'Support fee', 'Recurring reservation fee','Support'
                    ],
                    }
                }
    },    
    Metrics=['UnblendedCost'],
    GroupBy=[
        {
            'Type': 'DIMENSION',
            'Key': 'LINKED_ACCOUNT'
        },
    ]
)

client = boto3.client('ce')
response_monthly = client.get_cost_and_usage(
    TimePeriod={
        'Start': days_month_start,
        'End': yesterday
    },
    Granularity='DAILY',
    Filter={
        'Not': {
            'Dimensions': {
            'Key': 'RECORD_TYPE',
            'Values': [
                'Credit', 'Distributor Discount', 'Support fee', 'Recurring reservation fee','Support'
                    ],
                    }
                }
    },    
    Metrics=['UnblendedCost'],
    GroupBy=[
        {
            'Type': 'DIMENSION',
            'Key': 'LINKED_ACCOUNT'
        },
    ]
)

def now_cost(response):
    # Create a dictionary to store account IDs as keys and their respective descriptions and amounts as values
    account_data = {}

    # Loop through the response and populate the account_data dictionary
    for time in response['ResultsByTime']:
        timestart = time['TimePeriod']['Start']
        for group in time['Groups']:
            account_id = group['Keys'][0]
            amount = float(group['Metrics']['UnblendedCost']['Amount'])
    
            # Find the corresponding description for the account ID
            description = None
            for attribute in response['DimensionValueAttributes']:
                if attribute['Value'] == account_id:
                    description = attribute['Attributes']['description']
                    break

            # Store the data in the dictionary
            account_data[account_id] = {'description': description, 'amount': amount, 'time': timestart}

    return account_data
 

def avg_monthly_cost(response):
    # Create a dictionary to store account IDs as keys and their respective descriptions and amounts as values
    account_data = {}

    # Loop through the response and populate the account_data dictionary
    for time in response['ResultsByTime']:
        #timestart = time['TimePeriod']['Start']
        for group in time['Groups']:
            account_id = group['Keys'][0]
            amount = float(group['Metrics']['UnblendedCost']['Amount'])

            # Find the corresponding description for the account ID
            description = None
            for attribute in response['DimensionValueAttributes']:
                if attribute['Value'] == account_id:
                    description = attribute['Attributes']['description']
                    break
            # Create a new entry for the account if it doesn't exist    
            if account_id not in account_data:
              #account_data[account_id] = {'time_periods': [], 'amounts': [],'account name':[description]}  
              account_data[account_id] = {'amounts': [],'account name':[description]} 

            # Append the data for the amount is greater than or equal to 0.01
            if amount >= 0.01:
                #account_data[account_id]['time_periods'].append(timestart)
                account_data[account_id]['amounts'].append(amount)

    # Calculate the count and sum of amounts for each account
    for account_id, data in account_data.items():
        data['count'] = len(data['amounts'])
        data['sum'] = sum(data['amounts'])
        # Calculate the average and store it in the dictionary
        if data['count'] >= 7:
            data['average'] = (data['sum'] / data['count']) * 2
        else:
            data['average'] = 0.0  # Avoid division by zero
        
    return account_data

x = now_cost(response_now)
y = avg_monthly_cost(response_monthly)
print(y)

cost_nows = []
cost_avgs = []
account_ids = []
cus_names = []
# Compare 'amount' values for the same 'account_id' and send email if condition is met
for account_id in x.keys():
    cost_now = x[account_id]['amount']
    time = x[account_id]['time']
    cus_name = x[account_id]['description']
    cost_avg = y[account_id]['average']

    if account_id in y and cost_now > cost_avg and cost_now > 5 and cost_avg > 5:
        cost_nows.append(f"{cost_now:.2f}")
        cost_avgs.append(f"{cost_avg:.2f}")
        account_ids.append(account_id)
        cus_names.append(cus_name)
        write_to_csv(time,account_ids,cus_names,cost_nows,cost_avgs,output_filename,column_names)
        #print(f"Account :{account_id} today cost is {cost_now:.2f} is greater than Avg. {cost_avg:.2f}")
    else:
        #print(f"Account :{account_id} is not greater.")
        continue
if account_ids:
    message = f"This is e-mail alert : AWS Account cost usage over average at {time}"
    print("Script was successful and Report are generated :)")
    # Call the function to send the email with attachment
    send_email(sender, receivers, subject, message, smtp_server, smtp_port, output_filename) 
else:
    print("Not have account over limit")
