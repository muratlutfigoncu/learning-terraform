terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = ">= 5.0.0"
        }
    }

    required_version = ">= 1.2.0"
}


provider "aws" {
    region = "eu-central-1"
    profile = "default"

    default_tags {
        tags = {
            Name = "Lambda-Layers"
        }
    }
}

locals {
  layer_zip_path    = "layer.zip"
  layer_name        = "terraform_lambda_layer"
  requirements_path = "${path.root}/lambda-function/requirements.txt"
}

resource "aws_s3_bucket" "terraform-bucket" {
  bucket = "muratgoncu-terraform"
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
}


resource "aws_lambda_function" "lambda_function" {
  function_name = "HelloWorld"

  s3_bucket = aws_s3_bucket.terraform-bucket.id
  s3_key    = aws_s3_object.lambda_function.key

  runtime = "python3.9"
  handler = "app.lambda_handler"

  source_code_hash = data.archive_file.lambda_function.output_base64sha256

  role = aws_iam_role.lambda_exec_role.arn
  layers = [aws_lambda_layer_version.my-lambda-layer.arn]
}


resource "aws_iam_role" "lambda_exec_role"{
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
        }]
    })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

}

resource "aws_cloudwatch_log_group" "lambda_function" {
  name = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = 30
}


# create a zip from requirements
resource "null_resource" "lambda_layer" {

  # the command to install python and dependencies to the machine and zips
    # set -e
    #   apt-get update
    #   apt install python3 python3-pip zip -y
    #   rm -rf python
  provisioner "local-exec" {
    command = <<EOT
      mkdir python
      pip3 install -r ${local.requirements_path} -t python/
      zip -r ${local.layer_zip_path} python/
    EOT
  }
}

#bucket = 

# upload zip file to s3
resource "aws_s3_object" "lambda_layer_zip" {
  bucket     = aws_s3_bucket.terraform-bucket.id
  key        = "lambda_layers/${local.layer_name}/${local.layer_zip_path}"
  source     = local.layer_zip_path
  depends_on = [null_resource.lambda_layer] # triggered only if the zip file is created
}

# create lambda layer from s3 object
resource "aws_lambda_layer_version" "my-lambda-layer" {
  s3_bucket           = aws_s3_bucket.terraform-bucket.id
  s3_key              = aws_s3_object.lambda_layer_zip.key
  layer_name          = local.layer_name
  compatible_runtimes = ["python3.9"]
  skip_destroy        = true
  depends_on          = [aws_s3_object.lambda_layer_zip] # triggered only if the zip file is uploaded to the bucket
}