data "archive_file" "python_lambda_package" {  
  type = "zip"  
  source_file = "${path.module}/generate_index.py" 
  output_path = "${path.module}/package.zip"
}

resource "aws_lambda_function" "generate_index" {
  filename      = "${path.module}/package.zip"
  source_code_hash = data.archive_file.python_lambda_package.output_base64sha256
  function_name = "generate_index"
  role          = aws_iam_role.lambda_role.arn
  handler       = "generate_index.lambda_handler"
  runtime = "python3.9"
  timeout = 300
  tags = {
    Environment = "dev"
    Management = "Terraform"
  }

  environment {
    variables = {
      TZ = "America/Sao_Paulo"
      roleArn = aws_iam_role.lambda_role.arn
      BUCKET_NAME = aws_s3_bucket.app_bucket.id
      BUCKET_PREFIX = "/apis"
      CLOUDFRONT_URL = aws_cloudfront_distribution.openapi_cdn.domain_name
    }
  }
}

resource "aws_lambda_permission" "allow_source_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_index.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.app_bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.app_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.generate_index.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "apis/"
    filter_suffix       = ".yaml"
  }
}
