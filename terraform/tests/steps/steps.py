from behave import given, when, then
from unittest.mock import NonCallableMagicMock, MagicMock, patch

from files.LambdaStartStopInstance import start_instances, stop_instances, time_checked_start_instances, time_checked_stop_instances

mock_context = NonCallableMagicMock(name='context')
mock_event = NonCallableMagicMock(name='event')


@given(u'there are instances {instances}')
def step_impl_given_instances(context, instances):
    instanceNames = instances.split(',')
    context.instanceNames = instanceNames


@given(u'the current hour is {time}')
def step_impl_given_current_time(context, time):
    context.timeNow = int(time)


@when(u'the instances are turned on')
@patch('files.LambdaStartStopInstance.ec2')
def step_impl_when_instances_turned_on(context, mock_ec2):
    mock_ec2.get_paginator.return_value.paginate.return_value = [{'Reservations': [{'Groups': 'Totally real security groups', 'Instances': [create_fake_instance_record(instanceName) for instanceName in context.instanceNames]}]}]
    start_instances(mock_event, mock_context)
    context.mock_ec2 = mock_ec2


@when(u'the instances are turned off')
@patch('files.LambdaStartStopInstance.ec2')
def step_impl_when_instances_turned_off(context, mock_ec2):
    mock_ec2.get_paginator.return_value.paginate.return_value = [{'Reservations': [{'Groups': 'Totally real security groups', 'Instances': [create_fake_instance_record(instanceName) for instanceName in context.instanceNames]}]}]
    stop_instances(mock_event, mock_context)
    context.mock_ec2 = mock_ec2


@when(u'the instances are turned on with a time check')
@patch('files.LambdaStartStopInstance.os')
@patch('files.LambdaStartStopInstance.datetime.datetime')
@patch('files.LambdaStartStopInstance.ec2')
def step_impl_when_instances_time_check_on(context, mock_ec2, mock_time, mock_env):
    mock_ec2.get_paginator.return_value.paginate.return_value = [{'Reservations': [{'Groups': 'Totally real security groups', 'Instances': [create_fake_instance_record(instanceName) for instanceName in context.instanceNames]}]}]
    mock_time.now.return_value = MagicMock(hour=context.timeNow)
    time_checked_start_instances(mock_context, mock_event)
    context.mock_ec2 = mock_ec2


@when(u'the instances are turned off with a time check')
@patch('files.LambdaStartStopInstance.os')
@patch('files.LambdaStartStopInstance.datetime.datetime')
@patch('files.LambdaStartStopInstance.ec2')
def step_impl_when_instances_time_check_on(context, mock_ec2, mock_time, mock_env):
    mock_ec2.get_paginator.return_value.paginate.return_value = [{'Reservations': [{'Groups': 'Totally real security groups', 'Instances': [create_fake_instance_record(instanceName) for instanceName in context.instanceNames]}]}]
    mock_time.now.return_value = MagicMock(hour=context.timeNow)
    time_checked_stop_instances(mock_context, mock_event)
    context.mock_ec2 = mock_ec2


@then(u'all of the instances should be turned on')
def step_impl_then_turned_on(context):
    context.mock_ec2.start_instances.assert_called()
    context.mock_ec2.stop_instances.assert_not_called()
    context.mock_ec2.start_instances.assert_called_with(InstanceIds=context.instanceNames)


@then(u'all of the instances should be turned off')
def step_impl_then_turned_off(context):
    context.mock_ec2.stop_instances.assert_called()
    context.mock_ec2.start_instances.assert_not_called()
    context.mock_ec2.stop_instances.assert_called_with(InstanceIds=context.instanceNames)


@then(u'the instances {should_or_should_not} be turned on')
def step_impl_then_should_or_not_be_turned_on(context, should_or_should_not):
    if should_or_should_not == 'should':
        context.mock_ec2.start_instances.assert_called()
        context.mock_ec2.start_instances.assert_called_with(InstanceIds=context.instanceNames)
        context.mock_ec2.stop_instances.assert_not_called()
    else:
        context.mock_ec2.start_instances.assert_not_called()
        context.mock_ec2.stop_instances.assert_not_called()


@then(u'the instances {should_or_should_not} be turned off')
def step_impl_then_should_or_not_be_turned_on(context, should_or_should_not):
    if should_or_should_not == 'should':
        context.mock_ec2.stop_instances.assert_called()
        context.mock_ec2.stop_instances.assert_called_with(InstanceIds=context.instanceNames)
        context.mock_ec2.start_instances.assert_not_called()
    else:
        context.mock_ec2.start_instances.assert_not_called()
        context.mock_ec2.stop_instances.assert_not_called()


def create_fake_instance_record(instanceId):
    return {'InstanceId': instanceId, 'otherData': 'other real and convincing information about the instance.'}
