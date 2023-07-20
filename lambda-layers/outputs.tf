output "lambda_layer_arn" {
  description = "ARN of Lambda Layer"

  value = aws_lambda_layer_version.my-lambda-layer.arn
}
