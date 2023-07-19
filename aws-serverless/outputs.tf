output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.lambda_function.function_name
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.lambda.invoke_url
}

output "dynamodb_arn" {
  description = "ARN of DynamoDB"

  value = aws_dynamodb_table.serverless-dynamodb-table.arn
}
