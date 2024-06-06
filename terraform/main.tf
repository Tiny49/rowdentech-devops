locals {
  daylight_savings_start_time = var.start_time_hour - 1
  daylight_savings_stop_time  = var.stop_time_hour - 1
}

# Creating lambda code file sources
data "template_file" "lambda_code" {
  count    = var.startup_shutdown == "yes" ? 1 : 0
  template = file("${path.module}/files/LambdaStartStopInstance.py")
}

data "archive_file" "zip_lambda_code" {
  count       = var.startup_shutdown == "yes" ? 1 : 0
  type        = "zip"
  output_path = "./files/LambdaStartStopInstance.zip"

  source {
    content  = data.template_file.lambda_code[0].rendered
    filename = "LambdaStartStopInstance.py"
  }
}

# Giving lambdas assume role permissions

resource "aws_iam_role" "startup_shutdown_lambda_role" {
  count              = var.startup_shutdown == "yes" ? 1 : 0
  name               = "${terraform.workspace}-Ec2StartupShutdownLambdaRole"
  assume_role_policy = file("${path.module}/files/LambdaAssumeRolePolicy.json")
}

resource "aws_iam_policy" "startup_shutdown_lambda_policy" {
  count       = var.startup_shutdown == "yes" ? 1 : 0
  name        = "${terraform.workspace}-Ec2StartupShutdownLambdaPolicy"
  path        = "/"
  description = "IAM policy to allow a lambda to start and stop ec2 instances"
  policy      = file("${path.module}/files/StartupShutdownLambdaPolicy.json")
}

resource "aws_iam_role_policy_attachment" "attatch_startup_shutdown_lambda_policy" {
  count      = var.startup_shutdown == "yes" ? 1 : 0
  role       = aws_iam_role.startup_shutdown_lambda_role[0].name
  policy_arn = aws_iam_policy.startup_shutdown_lambda_policy[0].arn
}

# Start-Shutdown lambda creations

resource "aws_lambda_function" "shutdown_lambda" {
  count            = var.startup_shutdown == "yes" ? 1 : 0
  filename         = data.archive_file.zip_lambda_code[0].output_path
  source_code_hash = filebase64sha256(data.archive_file.zip_lambda_code[0].output_path)
  function_name    = "tooling-lambda-ec2shutdown"
  handler          = "LambdaStartStopInstance.stop_instances"
  role             = aws_iam_role.startup_shutdown_lambda_role[0].arn
  runtime          = "python3.11"
  timeout          = 10
  environment {
    variables = {
      shutdownDefault = var.default_shutdown
    }
  }
}

resource "aws_lambda_function" "startup_lambda" {
  count            = var.startup_shutdown == "yes" ? 1 : 0
  filename         = data.archive_file.zip_lambda_code[0].output_path
  source_code_hash = filebase64sha256(data.archive_file.zip_lambda_code[0].output_path)
  function_name    = "${terraform.workspace}-lambda-ec2startup"
  handler          = "LambdaStartStopInstance.start_instances"
  role             = aws_iam_role.startup_shutdown_lambda_role[0].arn
  runtime          = "python3.11"
  timeout          = 10
}

resource "aws_lambda_function" "time_check_shutdown_lambda" {
  count            = var.startup_shutdown == "yes" ? 1 : 0
  filename         = data.archive_file.zip_lambda_code[0].output_path
  source_code_hash = filebase64sha256(data.archive_file.zip_lambda_code[0].output_path)
  function_name    = "${terraform.workspace}-lambda-time-checked-ec2shutdown"
  handler          = "LambdaStartStopInstance.time_checked_stop_instances"
  role             = aws_iam_role.startup_shutdown_lambda_role[0].arn
  runtime          = "python3.11"
  timeout          = 10
  environment {
    variables = {
      requestedStopHour = var.stop_time_hour
      shutdownDefault   = var.default_shutdown
    }
  }
}

resource "aws_lambda_function" "time_check_startup_lambda" {
  count            = var.startup_shutdown == "yes" ? 1 : 0
  filename         = data.archive_file.zip_lambda_code[0].output_path
  source_code_hash = filebase64sha256(data.archive_file.zip_lambda_code[0].output_path)
  function_name    = "tooling-lambda-time-checked-ec2startup"
  handler          = "LambdaStartStopInstance.time_checked_start_instances"
  role             = aws_iam_role.startup_shutdown_lambda_role[0].arn
  runtime          = "python3.11"
  timeout          = 10
  environment {
    variables = {
      requestedStartHour = var.start_time_hour
    }
  }
}

# Adding cloudwatch rules to trigger lambdas at start and stop times throughout year regardless of daylights savings
# Creating cloudwatch rules for time triggers though the year
resource "aws_cloudwatch_event_rule" "startup_summer_time_event_rule" {
  count = var.startup_shutdown == "yes" ? 1 : 0
  name  = "startup_summer_time"
  schedule_expression = "cron(${join(
    " ",
    [
      var.start_time_minute,
      local.daylight_savings_start_time,
      "?",
      "APR-SEP",
      "MON-FRI",
      "*",
    ],
  )})"
}

resource "aws_cloudwatch_event_rule" "shutdown_summer_time_event_rule" {
  count = var.startup_shutdown == "yes" ? 1 : 0
  name  = "shutdown_summer_time"
  schedule_expression = "cron(${join(
    " ",
    [
      var.stop_time_minute,
      local.daylight_savings_stop_time,
      "?",
      "APR-SEP",
      "MON-FRI",
      "*",
    ],
  )})"
}

resource "aws_cloudwatch_event_rule" "startup_winter_time_event_rule" {
  count = var.startup_shutdown == "yes" ? 1 : 0
  name  = "startup_winter_time"
  schedule_expression = "cron(${join(
    " ",
    [
      var.start_time_minute,
      var.start_time_hour,
      "?",
      "NOV,DEC,JAN,FEB",
      "MON-FRI",
      "*",
    ],
  )})"
}

resource "aws_cloudwatch_event_rule" "shutdown_winter_time_event_rule" {
  count = var.startup_shutdown == "yes" ? 1 : 0
  name  = "shutdown_winter_time"
  schedule_expression = "cron(${join(
    " ",
    [
      var.stop_time_minute,
      var.stop_time_hour,
      "?",
      "NOV,DEC,JAN,FEB",
      "MON-FRI",
      "*",
    ],
  )})"
}

resource "aws_cloudwatch_event_rule" "startup_daylight_savings_changeover_event_rule" {
  count = var.startup_shutdown == "yes" ? 1 : 0
  name  = "startup_daylights_savings_changeover"
  schedule_expression = "cron(${join(
    " ",
    [
      var.start_time_minute,
      join(
        ",",
        [local.daylight_savings_start_time, var.start_time_hour],
      ),
      "?",
      "OCT,MAR",
      "MON-FRI",
      "*",
    ],
  )})"
}

resource "aws_cloudwatch_event_rule" "shutdown_daylight_savings_changeover_event_rule" {
  count = var.startup_shutdown == "yes" ? 1 : 0
  name  = "shutdown_daylights_savings_changeover"
  schedule_expression = "cron(${join(
    " ",
    [
      var.stop_time_minute,
      join(",", [local.daylight_savings_stop_time, var.stop_time_hour]),
      "?",
      "OCT,MAR",
      "MON-FRI",
      "*",
    ],
  )})"
}

# Connecting the event rules to the appropriate lambdas and giving the rules permission to invoke the lambdas
resource "aws_cloudwatch_event_target" "startup_summer_time_rule_target" {
  count = var.startup_shutdown == "yes" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.startup_summer_time_event_rule[0].name
  arn   = aws_lambda_function.startup_lambda[0].arn
}

resource "aws_lambda_permission" "startup_summer_time_rule_invoke_lambda_permission" {
  count         = var.startup_shutdown == "yes" ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.startup_lambda[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.startup_summer_time_event_rule[0].arn
}

resource "aws_cloudwatch_event_target" "shutdown_summer_time_rule_target" {
  count = var.startup_shutdown == "yes" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.shutdown_summer_time_event_rule[0].name
  arn   = aws_lambda_function.shutdown_lambda[0].arn
}

resource "aws_lambda_permission" "shutdown_summer_time_rule_invoke_lambda_permission" {
  count         = var.startup_shutdown == "yes" ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shutdown_lambda[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.shutdown_summer_time_event_rule[0].arn
}

resource "aws_cloudwatch_event_target" "startup_winter_time_rule_target" {
  count = var.startup_shutdown == "yes" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.startup_winter_time_event_rule[0].name
  arn   = aws_lambda_function.startup_lambda[0].arn
}

resource "aws_lambda_permission" "startup_winter_time_rule_invoke_lambda_permission" {
  count         = var.startup_shutdown == "yes" ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.startup_lambda[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.startup_winter_time_event_rule[0].arn
}

resource "aws_cloudwatch_event_target" "shutdown_winter_time_rule_target" {
  count = var.startup_shutdown == "yes" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.shutdown_winter_time_event_rule[0].name
  arn   = aws_lambda_function.shutdown_lambda[0].arn
}

resource "aws_lambda_permission" "shutdown_winter_time_rule_invoke_lambda_permission" {
  count         = var.startup_shutdown == "yes" ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shutdown_lambda[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.shutdown_winter_time_event_rule[0].arn
}

resource "aws_cloudwatch_event_target" "startup_daylights_savings_rule_target" {
  count = var.startup_shutdown == "yes" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.startup_daylight_savings_changeover_event_rule[0].name
  arn   = aws_lambda_function.time_check_startup_lambda[0].arn
}

resource "aws_lambda_permission" "startup_daylights_savings_rule_invoke_lambda_permission" {
  count         = var.startup_shutdown == "yes" ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.time_check_startup_lambda[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.startup_daylight_savings_changeover_event_rule[0].arn
}

resource "aws_cloudwatch_event_target" "shutdown_daylights_savings_rule_target" {
  count = var.startup_shutdown == "yes" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.shutdown_daylight_savings_changeover_event_rule[0].name
  arn   = aws_lambda_function.time_check_shutdown_lambda[0].arn
}

resource "aws_lambda_permission" "shutdown_daylights_savings_rule_incoke_lambda_permission" {
  count         = var.startup_shutdown == "yes" ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.time_check_shutdown_lambda[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.shutdown_daylight_savings_changeover_event_rule[0].arn
}

