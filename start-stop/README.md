# ec2 Startup and Shutdown

##How it works

Deploys lambdas and cloudwatch rules to start and stop ec2 instances which have been tagged with the {"Rowden": "7-7"} tag.
Appropriately tagged instances are started at the scheduled start and stop times.
The module defaults to starting instances at 7am and stopping instances at 7pm.
Either or both of these scheduled times can be overridden via the variable with which the module is called.

As aws scheduled rules operate on UTC, daylights savings has had to be taken in to account.
Due to this lambdas are run four times a day rather then twice a day during October and March.
When run during October and March the lambda checks that the local time is matches the scheduled start/stop times before starting or stopping any instances.
The reasoning behind this decision was due to lambda run time being considerably cheaper than instance time however there are other options as to how to handle the daylights savings issue if required.

## Input Variables

The module uses the following input variables. 
All of these input variable have default values, meaning the variable only needs to be defined if the default needs to be overridden.

| Variable          | Default   | Description                                                       |
| ----------------- | --------- | ----------------------------------------------------------------- |
| startup_shutdown  | no        | Whether to deploy the startup-shutdown solution. Must have yes or no value.   |
| start_time_hour   | 7         | The hour component of the time to start instances at each weekday. Must be given as an integer value in 24 hours time. Defaults to 7am.   |
| start_time_minute | 00        | The minute component of the time to start instances at each weekday. Defaults to on the hour. |
| stop_time_hour    | 19        | The hour component of the time to stop instances at each weekday. Must be given as an integer value in 24 hour time. Defaults to 7pm. |
| stop_time_minute  | 00        | The minute component of the time to stop instances at each weekday. Defaults to on the hour.  | 

##Testing

The functionality of each of the lambdas is proven via tests written in gherkin.
To run the tests locally, first make sure you have python version 3 or later installed, 
and from the root of the account-baseline project run the following bash commands:

```bash
pip install virtualenv
pip install behave
pip install boto3
virutalenv .env
```

The test can then be run using the following command:
```bash
behave tests/
```
