import boto3
import json
from datetime import datetime, timedelta

def convert_json(data):
    json_object = json.dumps(data,indent=2) 
    return json_object

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
    Granularity='MONTHLY',
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

z = now_cost(response_now)
ans = convert_json(z)   
#print(ans)   

def monthly_cost(response):
    account_sum = {}

    for time in response['ResultsByTime']:
        datestart = time['TimePeriod']['Start']
        dateend = time['TimePeriod']['End']
        for group in time['Groups']:
            account_id = group['Keys'][0]
            amount = float(group['Metrics']['UnblendedCost']['Amount'])
            
            #print(f"Account id:{account_id},Amount :{amount} USD")

            if account_id in account_sum:
                account_sum[account_id]['amount'] += amount
            else:
                account_sum[account_id] = {'amount': amount}
    return account_sum

def monthly_cost_avg(response):
    account_sum = {}

    for time in response['ResultsByTime']:
        datestart = time['TimePeriod']['Start']
        dateend = time['TimePeriod']['End']
        for group in time['Groups']:
            account_id = group['Keys'][0]
            amount = float(group['Metrics']['UnblendedCost']['Amount'])
            avg = amount/30
            #print(f"Account id:{account_id},Amount :{amount} USD")

            if account_id in account_sum:
                account_sum[account_id]['amount'] += avg
            else:
                account_sum[account_id] = {'amount': avg}
    return account_sum

x = now_cost(response_now)
y = monthly_cost_avg(response_monthly)
z = monthly_cost(response_monthly)

#print(x)
#print(y)

# Compare 'amount' values for the same 'account_id' and send email if condition is met
for account_id in x.keys():
    cost_now = x[account_id]['amount']
    cost_avg = y[account_id]['amount']
    if account_id in y and cost_now > cost_avg:
        print(f"Account :{account_id} today cost is {cost_now:.2f} is greater than Avg. {cost_avg:.2f}")
    else:
        print(f"Account :{account_id} is not greater.")



 



