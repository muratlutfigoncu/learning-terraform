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

  runtime = "nodejs18.x"
  handler = "function.handler"

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

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

}