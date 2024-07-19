locals {
  suffix = data.terraform_remote_state.state1.outputs.suffix
}

resource "aws_dynamodb_table" "example" {
  name         = "rest-api-gw-${local.suffix}"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "NoteId"
    type = "N"
  }

  hash_key  = "UserId"
  range_key = "NoteId"

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_dynamodb_table_item" "testuser_1" {
  table_name = aws_dynamodb_table.example.name
  hash_key   = "UserId"
  range_key  = "NoteId"

  item = jsonencode({
    UserId = { S = "testuser" }
    NoteId = { N = "1" }
    Note   = { S = "hello world" }
  })
}

resource "aws_dynamodb_table_item" "testuser_2" {
  table_name = aws_dynamodb_table.example.name
  hash_key   = "UserId"
  range_key  = "NoteId"

  item = jsonencode({
    UserId = { S = "testuser" }
    NoteId = { N = "2" }
    Note   = { S = "this is my first note" }
  })
}

resource "aws_dynamodb_table_item" "student2_3" {
  table_name = aws_dynamodb_table.example.name
  hash_key   = "UserId"
  range_key  = "NoteId"

  item = jsonencode({
    UserId = { S = "student2" }
    NoteId = { N = "3" }
    Note   = { S = "PartiQL is a SQL compatible language for DynamoDB" }
  })
}

resource "aws_dynamodb_table_item" "student2_4" {
  table_name = aws_dynamodb_table.example.name
  hash_key   = "UserId"
  range_key  = "NoteId"

  item = jsonencode({
    UserId = { S = "student2" }
    NoteId = { N = "4" }
    Note   = { S = "I love DyDB" }
  })
}

resource "aws_dynamodb_table_item" "student2_5" {
  table_name = aws_dynamodb_table.example.name
  hash_key   = "UserId"
  range_key  = "NoteId"

  item = jsonencode({
    UserId = { S = "student2" }
    NoteId = { N = "5" }
    Note   = { S = "Maximum size of an item is ____ KB ?" }
  })
}

resource "aws_dynamodb_table_item" "student_1" {
  table_name = aws_dynamodb_table.example.name
  hash_key   = "UserId"
  range_key  = "NoteId"

  item = jsonencode({
    UserId = { S = "student" }
    NoteId = { N = "1" }
    Note   = { S = "DynamoDB is NoSQL" }
  })
}

resource "aws_dynamodb_table_item" "student_2" {
  table_name = aws_dynamodb_table.example.name
  hash_key   = "UserId"
  range_key  = "NoteId"

  item = jsonencode({
    UserId = { S = "student" }
    NoteId = { N = "2" }
    Note   = { S = "A DynamoDB table is schemaless" }
  })
}

resource "aws_dynamodb_table_item" "student_3" {
  table_name = aws_dynamodb_table.example.name
  hash_key   = "UserId"
  range_key  = "NoteId"

  item = jsonencode({
    UserId = { S = "student" }
    NoteId = { N = "3" }
    Note   = { S = "This is your updated note using the Model validation" }
  })
}

resource "aws_dynamodb_table_item" "newbie_1" {
  table_name = aws_dynamodb_table.example.name
  hash_key   = "UserId"
  range_key  = "NoteId"

  item = jsonencode({
    UserId = { S = "newbie" }
    NoteId = { N = "1" }
    Note   = { S = "Free swag code: 1234" }
  })
}

resource "aws_dynamodb_table_item" "newbie_2" {
  table_name = aws_dynamodb_table.example.name
  hash_key   = "UserId"
  range_key  = "NoteId"

  item = jsonencode({
    UserId = { S = "newbie" }
    NoteId = { N = "2" }
    Note   = { S = "I love DynamoDB" }
  })
}

resource "aws_cloudwatch_log_group" "create" {
  name              = "/aws/lambda/rest-api-gw-${local.suffix}-create"
  retention_in_days = 1

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_cloudwatch_log_group" "list" {
  name              = "/aws/lambda/rest-api-gw-${local.suffix}-list"
  retention_in_days = 1

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_role" "create" {
  name = "rest-api-gw-${local.suffix}-create"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "create" {
  name = "rest-api-gw-${local.suffix}-create"
  role = aws_iam_role.create.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DescribeTable"
        ],
        "Resource" : "${aws_dynamodb_table.example.arn}",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "${aws_cloudwatch_log_group.create.arn}",
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_lambda_function" "create" {
  filename         = "${path.module}/../01/external/create_function.zip"
  function_name    = "rest-api-gw-${local.suffix}-create"
  role             = aws_iam_role.create.arn
  handler          = "app.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/../01/external/create_function.zip")
  runtime          = "python3.12"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.example.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.create
  ]
}

resource "aws_iam_role" "list" {
  name = "rest-api-gw-${local.suffix}-list"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "list" {
  name = "rest-api-gw-${local.suffix}-list"
  role = aws_iam_role.list.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        "Resource" : "${aws_dynamodb_table.example.arn}",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "${aws_cloudwatch_log_group.list.arn}",
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_lambda_function" "list" {
  filename         = "${path.module}/../01/external/list_function.zip"
  function_name    = "rest-api-gw-${local.suffix}-list"
  role             = aws_iam_role.list.arn
  handler          = "app.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/../01/external/list_function.zip")
  runtime          = "python3.12"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.example.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.list
  ]
}

resource "aws_api_gateway_rest_api" "example" {
  name = "rest-api-gw-${local.suffix}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "notes" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  parent_id   = aws_api_gateway_rest_api.example.root_resource_id
  path_part   = "notes"
}

resource "aws_api_gateway_method" "notes_options" {
  rest_api_id   = aws_api_gateway_rest_api.example.id
  resource_id   = aws_api_gateway_resource.notes.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "notes_options" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.notes.id
  http_method = aws_api_gateway_method.notes_options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.notes_options]
}

resource "aws_api_gateway_integration" "notes_options" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.notes.id
  http_method = aws_api_gateway_method.notes_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [aws_api_gateway_method.notes_options, aws_api_gateway_method_response.notes_options]
}

resource "aws_api_gateway_integration_response" "notes_options" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.notes.id
  http_method = aws_api_gateway_method.notes_options.http_method
  status_code = aws_api_gateway_method_response.notes_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.notes_options,
    aws_api_gateway_method_response.notes_options
  ]
}

resource "aws_iam_role" "apigw_lambda" {
  name = "rest-api-gw-${local.suffix}-apigw-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "apigw_lambda_list" {
  name = "rest-api-gw-${local.suffix}-apigw-lambda-list"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = aws_lambda_function.list.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apigw_lambda_list" {
  role       = aws_iam_role.apigw_lambda.name
  policy_arn = aws_iam_policy.apigw_lambda_list.arn
}

resource "aws_iam_role_policy_attachment" "apigw_cloudwatch_policy" {
  role       = aws_iam_role.apigw_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_lambda_permission" "apigw_invoke_lambda_list" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}

resource "aws_api_gateway_method" "notes_get" {
  rest_api_id   = aws_api_gateway_rest_api.example.id
  resource_id   = aws_api_gateway_resource.notes.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "notes_get" {
  rest_api_id             = aws_api_gateway_rest_api.example.id
  resource_id             = aws_api_gateway_resource.notes.id
  http_method             = aws_api_gateway_method.notes_get.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.list.invoke_arn

  request_templates = {
    "application/json" = <<EOF
{
  "UserId": "student"
}
EOF
  }
}

resource "aws_api_gateway_method_response" "notes_get" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.notes.id
  http_method = aws_api_gateway_method.notes_get.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "notes_get" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.notes.id
  http_method = aws_api_gateway_method.notes_get.http_method
  status_code = aws_api_gateway_method_response.notes_get.status_code

  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
[
    #foreach($elem in $inputRoot)
    {
        "NoteId" : "$elem.NoteId",
        "Note" : "$elem.Note"
    }
    #if($foreach.hasNext),#end
    #end
]
EOF
  }

  depends_on = [
    aws_api_gateway_integration.notes_get
  ]
}

resource "aws_iam_policy" "apigw_lambda_create" {
  name = "rest-api-gw-${local.suffix}-apigw-lambda-create"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = aws_lambda_function.create.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apigw_lambda_create" {
  role       = aws_iam_role.apigw_lambda.name
  policy_arn = aws_iam_policy.apigw_lambda_create.arn
}

resource "aws_lambda_permission" "apigw_invoke_lambda_create" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}

resource "aws_api_gateway_method" "notes_post" {
  rest_api_id   = aws_api_gateway_rest_api.example.id
  resource_id   = aws_api_gateway_resource.notes.id
  http_method   = "POST"
  authorization = "NONE"

  request_models = {
    "application/json" = aws_api_gateway_model.example.name
  }
}

resource "aws_api_gateway_integration" "notes_post" {
  rest_api_id             = aws_api_gateway_rest_api.example.id
  resource_id             = aws_api_gateway_resource.notes.id
  http_method             = aws_api_gateway_method.notes_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.create.invoke_arn

  # request_templates = {
  #   "application/json" = ""
  # }
}

resource "aws_api_gateway_method_response" "notes_post" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.notes.id
  http_method = aws_api_gateway_method.notes_post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "notes_post" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.notes.id
  http_method = aws_api_gateway_method.notes_post.http_method
  status_code = aws_api_gateway_method_response.notes_post.status_code

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.notes_post
  ]
}

resource "aws_api_gateway_model" "example" {
  name         = "NoteModel"
  description  = "A schema model for notes"
  rest_api_id  = aws_api_gateway_rest_api.example.id
  content_type = "application/json"
  schema       = <<EOF
  {
    "title": "Note",
    "type": "object",
    "properties": {
      "UserId": {
        "type": "string"
      },
      "NoteId": {
        "type": "integer"
      },
      "Note": {
        "type": "string"
      }
    },
    "required": ["UserId", "NoteId", "Note"]
  }
  EOF
}

resource "aws_api_gateway_gateway_response" "default_4xx" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  response_type = "DEFAULT_4XX"

  response_templates = {
    "application/json" = "{\"message\":$context.error.messageString}"
  }
}

resource "aws_api_gateway_gateway_response" "default_5xx" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  response_type = "DEFAULT_5XX"

  response_templates = {
    "application/json" = "{\"message\":$context.error.messageString}"
  }
}

resource "aws_api_gateway_account" "example" {
  cloudwatch_role_arn = aws_iam_role.apigw_lambda.arn
}

resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.example.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_account.example,
    aws_api_gateway_integration.notes_get,
    aws_api_gateway_integration.notes_options,
    aws_api_gateway_integration.notes_post,
    aws_api_gateway_method_response.notes_get,
    aws_api_gateway_method_response.notes_options,
    aws_api_gateway_method_response.notes_post,
    aws_api_gateway_method.notes_get,
    aws_api_gateway_method.notes_options,
    aws_api_gateway_method.notes_post
  ]
}

resource "aws_cloudwatch_log_group" "rest_api_gw" {
  name              = "/aws/apigateway/rest-api-gw-${local.suffix}/prod"
  retention_in_days = 1

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.example.id
  stage_name    = "Prod"

  access_log_settings {
    destination_arn = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/rest-api-gw-${local.suffix}/prod"
    format          = jsonencode({
      requestId       = "$context.requestId",
      ip              = "$context.identity.sourceIp",
      caller          = "$context.identity.caller",
      user            = "$context.identity.user",
      requestTime     = "$context.requestTime",
      httpMethod      = "$context.httpMethod",
      resourcePath    = "$context.resourcePath",
      status          = "$context.status",
      protocol        = "$context.protocol",
      responseLength  = "$context.responseLength"
    })
  }

  depends_on = [
    aws_cloudwatch_log_group.rest_api_gw
  ]
}

resource "aws_api_gateway_method_settings" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  stage_name  = aws_api_gateway_stage.example.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

output "aws_api_gateway_invoke_url" {
  value = aws_api_gateway_stage.example.invoke_url
}

output "aws_api_gateway_notes_url" {
  value = "${aws_api_gateway_stage.example.invoke_url}/notes"
}
