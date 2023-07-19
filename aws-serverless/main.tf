terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-central-1"
}


resource "aws_s3_bucket" "terraform-bucket" {
  bucket = "muratgoncu-terraform"

  tags = {
    Name = "Terraform"
  }
}

data "archive_file" "lambda_function" {
  type = "zip"

  source_dir  = "${path.module}/lambda-function"
  output_path = "${path.module}/lambda-function.zip"
}

resource "aws_dynamodb_table" "serverless-dynamodb-table" {
  name           = "AWSServerlessTerraform"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "UserId"
  range_key      = "GameTitle"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "GameTitle"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  tags = {
    Name = "Terraform AWS Serverless"
  }
}

resource "aws_s3_object" "lambda_function" {

  bucket = aws_s3_bucket.terraform-bucket.id
  key    = "terraform-aws-serverless/hello-world.zip"
  source = data.archive_file.lambda_function.output_path

  etag = filemd5(data.archive_file.lambda_function.output_path)

  tags = {
    Name = "Terraform AWS Serverless"
  }
}

resource "aws_lambda_function" "lambda_function" {
  function_name = "HelloWorld"

  s3_bucket = aws_s3_bucket.terraform-bucket.id
  s3_key    = aws_s3_object.lambda_function.key

  runtime = "python3.7"
  handler = "app.lambda_handler"

  source_code_hash = data.archive_file.lambda_function.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  tags = {
    Name = "Terraform AWS Serverless"
  }
}


resource "aws_cloudwatch_log_group" "lambda_function" {
  name = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"

  retention_in_days = 30

  tags = {
    Name = "Terraform AWS Serverless"
  }
}


resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })

  tags = {
    Name = "Terraform AWS Serverless"
  }
}

resource "aws_iam_policy" "dynamoDBLambdaPolicy" {
  name = "serverless_lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Action = [ "dynamodb:*" ]
        Sid    = "LambdaAccessDynamo"
        Resource =[
          aws_dynamodb_table.serverless-dynamodb-table.arn
        ] 
      }
    ]
  })

  tags = {
    Name = "Terraform AWS Serverless"
  }
}


resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

}

resource "aws_iam_role_policy_attachment" "lambda-policy-attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.dynamoDBLambdaPolicy.arn
}


resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "lambda_function" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.lambda_function.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "lambda_function" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_function.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

# resource "aws_lambda_permission" "dynamodb" {
#   statement_id  = "AllowLambdaAccessDynamo"
#   action        = "dynamodb:GetItem"
#   function_name = aws_lambda_function.lambda_function.function_name
#   resource     = "${dynamodb_arn}"

#   source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
# }

