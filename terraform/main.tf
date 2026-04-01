### Lamdas
data "archive_file" "create_order_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lamdas/create_order"
  output_path = "${path.module}/../lamdas/create_order/create_order.zip"
}

resource "aws_lambda_function" "create_order" {
  function_name = "create_order"

  role    = aws_iam_role.lambda_role.arn
  handler = "handler_create_order.lambda_handler"
  runtime = "python3.11"

  filename         = data.archive_file.create_order_zip.output_path
  source_code_hash = data.archive_file.create_order_zip.output_base64sha256

  timeout     = 10
  memory_size = 128
}


data "archive_file" "prepare_order_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lamdas/prepare_order"
  output_path = "${path.module}/../lamdas/prepare_order/prepare_order.zip"
}

resource "aws_lambda_function" "prepare_order" {
  function_name = "prepare_order"

  role    = aws_iam_role.lambda_role.arn
  handler = "handler_prepare_order.lambda_handler"
  runtime = "python3.11"

  filename         = data.archive_file.prepare_order_zip.output_path
  source_code_hash = data.archive_file.prepare_order_zip.output_base64sha256

  timeout     = 10
  memory_size = 128
}

data "archive_file" "process_payment_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lamdas/process_payment"
  output_path = "${path.module}/../lamdas/process_payment/process_payment.zip"
}

resource "aws_lambda_function" "process_payment" {
  function_name = "process_payment"

  role    = aws_iam_role.lambda_role.arn
  handler = "handler_process_payment.lambda_handler"
  runtime = "python3.11"

  filename         = data.archive_file.process_payment_zip.output_path
  source_code_hash = data.archive_file.process_payment_zip.output_base64sha256

  timeout     = 10
  memory_size = 128
}

data "archive_file" "ship_order_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lamdas/ship_order"
  output_path = "${path.module}/../lamdas/ship_order/ship_order.zip"
}

resource "aws_lambda_function" "ship_order" {
  function_name = "ship_order"

  role    = aws_iam_role.lambda_role.arn
  handler = "handler_ship_order.lambda_handler"
  runtime = "python3.11"

  filename         = data.archive_file.ship_order_zip.output_path
  source_code_hash = data.archive_file.ship_order_zip.output_base64sha256

  timeout     = 10
  memory_size = 128
}

data "archive_file" "deliver_order_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lamdas/deliver_order"
  output_path = "${path.module}/../lamdas/deliver_order/deliver_order.zip"
}

resource "aws_lambda_function" "deliver_order" {
  function_name = "deliver_order"

  role    = aws_iam_role.lambda_role.arn
  handler = "handler_deliver_order.lambda_handler"
  runtime = "python3.11"

  filename         = data.archive_file.deliver_order_zip.output_path
  source_code_hash = data.archive_file.deliver_order_zip.output_base64sha256

  timeout     = 10
  memory_size = 128
}

###	 State machine step-funtions
resource "aws_sfn_state_machine" "order_flow" {
  name     = "order_flow"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    StartAt = "CreateOrder"
    States = {
      CreateOrder = {
        Type     = "Task"
        Resource = aws_lambda_function.create_order.arn
		ResultPath = "$"
		Retry: [
			{
			  "ErrorEquals": ["States.ALL"],
			  "IntervalSeconds": 1,
			  "MaxAttempts": 2,
			  "BackoffRate": 2.0
			}
	    ],
        Next     = "ProcessPayment"
      }
      ProcessPayment = {
        Type     = "Task"
        Resource = aws_lambda_function.process_payment.arn
		ResultPath = "$"
		Retry: [
			{
			  "ErrorEquals": ["States.ALL"],
			  "IntervalSeconds": 1,
			  "MaxAttempts": 2,
			  "BackoffRate": 2.0
			}
	    ],
        Next     = "PrepareOrder"
      }
      PrepareOrder = {
        Type     = "Task"
        Resource = aws_lambda_function.prepare_order.arn
		ResultPath = "$"
		Retry: [
			{
			  "ErrorEquals": ["States.ALL"],
			  "IntervalSeconds": 1,
			  "MaxAttempts": 2,
			  "BackoffRate": 2.0
			}
	    ],
        Next     = "ShipOrder"
      }
      ShipOrder = {
        Type     = "Task"
        Resource = aws_lambda_function.ship_order.arn
		ResultPath = "$"
		Retry: [
			{
			  "ErrorEquals": ["States.ALL"],
			  "IntervalSeconds": 1,
			  "MaxAttempts": 2,
			  "BackoffRate": 2.0
			}
	    ],
        Next     = "DeliverOrder"
      }
      DeliverOrder = {
        Type = "Task"
        Resource = aws_lambda_function.deliver_order.arn
		ResultPath = "$"
		Retry: [
			{
			  "ErrorEquals": ["States.ALL"],
			  "IntervalSeconds": 1,
			  "MaxAttempts": 2,
			  "BackoffRate": 2.0
			}
	    ],
        End = true
      }
    }
  })
}

# Roles definition
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "step_function_role" {
  name = "step_function_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "step_function_policy" {
  name = "step_function_lambda_policy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "*"
      }
    ]
  })
}




