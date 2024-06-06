import boto3
import datetime
import os

region = 'eu-west-2'
ec2 = boto3.client('ec2', region_name=region)

startTime = os.getenv('requestedStartHour', '7')
stopTime = os.getenv('requestedStopHour', '19')

try:
    shutdownDefault = True if os.environ['shutdownDefault'].lower() == 'yes' else False
except:
    pass

def time_checked_start_instances(event, context):
    if datetime.datetime.now().hour == int(startTime):
        start_instances(event, context)


def time_checked_stop_instances(event, context):
    if datetime.datetime.now().hour == int(stopTime):
        stop_instances(event, context)


def start_instances(event, context):
    instanceIds = get_instance_ids([{'Name': 'tag:Rowden', 'Values': ['7-7']},
                                     {'Name': 'instance-state-name', 'Values': ['stopped']}])
    if len(instanceIds) > 0:
        ec2.start_instances(InstanceIds=instanceIds)


def stop_instances(event, context):
    if shutdownDefault:
        instanceNeg = get_instance_ids([{'Name': 'tag:Rowden', 'Values': ['always on']},
                                         {'Name': 'instance-state-name', 'Values': ['running']}])
        instanceAll = get_instance_ids([{'Name': 'instance-state-name', 'Values': ['running']}])
        instanceIds = [instanceId for instanceId in instanceAll if instanceId not in instanceNeg]
    else:
        instanceIds = get_instance_ids([{'Name': 'tag:Rowden', 'Values': ['7-7', 'daily shutdown']},
                                         {'Name': 'instance-state-name', 'Values': ['running']}])
    if len(instanceIds) > 0:
        ec2.stop_instances(InstanceIds=instanceIds)


def get_instance_ids(instanceFilter):
    resultPages = ec2.get_paginator('describe_instances').paginate(Filters=instanceFilter)
    return [instance['InstanceId'] for page in resultPages for reservations in page['Reservations'] for instance in reservations['Instances']]
